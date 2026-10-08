import Vapor
import Fluent

/// Handles checkout (Square payment + order creation), customer order history,
/// and admin order management / logs.
struct OrderController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Checkout + customer order history.
        // sessionAuthenticator attaches the user if logged in, but does NOT require it,
        // so guests can also check out.
        let api = routes.grouped("api").grouped(User.sessionAuthenticator())
        api.post("checkout", use: checkout)

        let orders = api.grouped("orders").grouped(UserAuthenticatedMiddleware())
        orders.get(use: listMyOrders)
        orders.get(":orderID", use: getMyOrder)

        // Admin order management / logs (any authenticated admin can view).
        let adminOrders = routes.grouped("api", "admin", "orders")
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())
        adminOrders.get(use: adminListOrders)
        adminOrders.get(":orderID", use: adminGetOrder)

        // Updating an order's status is a management action (moderator or super admin).
        let adminOrdersManage = adminOrders.grouped(ModeratorMiddleware())
        adminOrdersManage.patch(":orderID", "status", use: adminUpdateStatus)
    }

    // MARK: - Checkout

    func checkout(req: Request) async throws -> OrderDTO {
        let data = try req.content.decode(CheckoutRequest.self)

        guard data.email.contains("@") else {
            throw Abort(.badRequest, reason: "A valid email address is required")
        }

        // Resolve the current cart (user or guest session) and load its items.
        guard let cart = try await currentCart(req: req) else {
            throw Abort(.badRequest, reason: "Your cart is empty")
        }
        let items = try await cart.$items.query(on: req.db).with(\.$product).all()
        guard !items.isEmpty else {
            throw Abort(.badRequest, reason: "Your cart is empty")
        }

        // Validate stock and compute the subtotal from current prices.
        var subtotal = 0.0
        for item in items {
            guard item.product.isActive else {
                throw Abort(.badRequest, reason: "\(item.product.name) is no longer available")
            }
            guard item.product.stockQuantity >= item.quantity else {
                throw Abort(.conflict, reason: "Not enough stock for \(item.product.name)")
            }
            subtotal += item.product.effectivePrice * Double(item.quantity)
        }

        let shippingAmount = Self.flatShippingAmount()
        let taxAmount = 0.0  // TODO: wire real tax calculation when rates are configured
        let total = subtotal + shippingAmount + taxAmount
        let amountCents = Int((total * 100).rounded())

        // Load Square configuration.
        guard let squareConfig = SquareConfiguration.fromEnvironment() else {
            req.logger.error("Checkout attempted but Square is not configured (missing env vars)")
            throw Abort(.serviceUnavailable, reason: "Payments are not configured")
        }

        let orderID = UUID()
        let orderNumber = Order.generateOrderNumber()

        // Charge the card via Square.
        let square = SquareService(config: squareConfig, client: req.client, logger: req.logger)
        let payment = try await square.createPayment(
            sourceID: data.sourceID,
            amountCents: amountCents,
            idempotencyKey: orderID.uuidString,
            referenceID: orderNumber,
            note: "Naturally Yours order \(orderNumber)"
        )

        guard SquareService.isSuccessful(status: payment.status) else {
            throw Abort(.paymentRequired, reason: "Payment was not completed (status: \(payment.status))")
        }

        // Persist the order + line items, decrement stock, and close the cart.
        let userID = req.auth.get(User.self)?.id
        let order = Order(
            id: orderID,
            orderNumber: orderNumber,
            userID: userID,
            email: data.email,
            customerName: data.customerName,
            phone: data.phone,
            shippingLine1: data.shipping.line1,
            shippingLine2: data.shipping.line2,
            shippingCity: data.shipping.city,
            shippingState: data.shipping.state,
            shippingPostalCode: data.shipping.postalCode,
            shippingCountry: data.shipping.country,
            subtotal: subtotal,
            taxAmount: taxAmount,
            shippingAmount: shippingAmount,
            total: total,
            status: .paid,
            squarePaymentID: payment.id,
            paymentStatus: payment.status,
            customerNote: data.customerNote
        )

        try await req.db.transaction { db in
            try await order.save(on: db)
            for item in items {
                let orderItem = OrderItem(
                    orderID: orderID,
                    productID: item.product.id,
                    productName: item.product.name,
                    sku: item.product.sku,
                    unitPrice: item.product.effectivePrice,
                    quantity: item.quantity
                )
                try await orderItem.save(on: db)

                // Decrement stock.
                item.product.stockQuantity -= item.quantity
                try await item.product.save(on: db)
            }

            // Close out the cart.
            try await CartItem.query(on: db).filter(\.$cart.$id == cart.id!).delete()
            cart.isActive = false
            try await cart.save(on: db)
        }

        req.logger.info("Order \(orderNumber) placed (\(payment.id)) total=$\(total)")

        // Reload with items for the response.
        try await order.$items.load(on: req.db)
        return order.toDTO()
    }

    // MARK: - Customer order history

    func listMyOrders(req: Request) async throws -> [OrderDTO] {
        let user = try req.auth.require(User.self)
        let orders = try await Order.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .sort(\.$createdAt, .descending)
            .with(\.$items)
            .all()
        return orders.map { $0.toDTO() }
    }

    func getMyOrder(req: Request) async throws -> OrderDTO {
        let user = try req.auth.require(User.self)
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        guard let order = try await Order.query(on: req.db)
            .filter(\.$id == orderID)
            .filter(\.$user.$id == user.id!)
            .with(\.$items)
            .first() else {
            throw Abort(.notFound, reason: "Order not found")
        }
        return order.toDTO()
    }

    // MARK: - Admin

    func adminListOrders(req: Request) async throws -> Page<OrderDTO> {
        let page = try await Order.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .with(\.$items)
            .paginate(for: req)
        return page.map { $0.toDTO() }
    }

    func adminGetOrder(req: Request) async throws -> OrderDTO {
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        guard let order = try await Order.query(on: req.db)
            .filter(\.$id == orderID)
            .with(\.$items)
            .first() else {
            throw Abort(.notFound, reason: "Order not found")
        }
        return order.toDTO()
    }

    func adminUpdateStatus(req: Request) async throws -> OrderDTO {
        let admin = try req.auth.require(Admin.self)
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        guard let order = try await Order.find(orderID, on: req.db) else {
            throw Abort(.notFound, reason: "Order not found")
        }

        struct UpdateStatusRequest: Content {
            let status: OrderStatus
        }
        let update = try req.content.decode(UpdateStatusRequest.self)
        order.status = update.status
        try await order.save(on: req.db)

        req.logger.info("Admin \(admin.email) set order \(order.orderNumber) status=\(update.status.rawValue)")

        try await order.$items.load(on: req.db)
        return order.toDTO()
    }

    // MARK: - Helpers

    /// Finds the active cart for the current user or guest session (does not create one).
    private func currentCart(req: Request) async throws -> Cart? {
        if let user = req.auth.get(User.self), let userID = user.id {
            return try await Cart.query(on: req.db)
                .filter(\.$user.$id == userID)
                .filter(\.$isActive == true)
                .first()
        } else if let sessionID = req.session.data["cart_session_id"] {
            return try await Cart.query(on: req.db)
                .filter(\.$sessionID == sessionID)
                .filter(\.$isActive == true)
                .first()
        }
        return nil
    }

    /// Flat shipping amount in dollars, from `SHIPPING_FLAT_CENTS` (default 0).
    private static func flatShippingAmount() -> Double {
        guard let cents = Environment.get("SHIPPING_FLAT_CENTS").flatMap(Int.init) else { return 0 }
        return Double(cents) / 100.0
    }
}

// MARK: - Request payload

struct CheckoutRequest: Content {
    /// Payment token from the Square In-App Payments SDK.
    let sourceID: String
    let email: String
    let customerName: String
    let phone: String?
    let shipping: ShippingAddressPayload
    let customerNote: String?
}
