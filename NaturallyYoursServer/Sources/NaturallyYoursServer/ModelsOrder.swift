import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// The lifecycle status of an order.
enum OrderStatus: String, Codable, Sendable, CaseIterable {
    case pendingPayment = "pending_payment"  // created but payment not yet confirmed
    case paid                                 // payment captured via Square
    case fulfilled                            // shipped / completed
    case cancelled
    case refunded
}

/// Represents a customer order (placed by a registered user or a guest).
final class Order: Model, @unchecked Sendable {
    static let schema = "orders"

    @ID(key: .id)
    var id: UUID?

    /// Human-friendly order number shown to the customer (e.g. "NY-4F9A2C").
    @Field(key: "order_number")
    var orderNumber: String

    /// Owning user — null for guest checkouts.
    @OptionalParent(key: "user_id")
    var user: User?

    // Contact / customer snapshot (kept even for registered users for historical accuracy)
    @Field(key: "email")
    var email: String

    @Field(key: "customer_name")
    var customerName: String

    @OptionalField(key: "phone")
    var phone: String?

    // Shipping address
    @Field(key: "shipping_line1")
    var shippingLine1: String

    @OptionalField(key: "shipping_line2")
    var shippingLine2: String?

    @Field(key: "shipping_city")
    var shippingCity: String

    @Field(key: "shipping_state")
    var shippingState: String

    @Field(key: "shipping_postal_code")
    var shippingPostalCode: String

    @Field(key: "shipping_country")
    var shippingCountry: String

    // Monetary amounts (stored in dollars as Double to match the Product model)
    @Field(key: "subtotal")
    var subtotal: Double

    @Field(key: "tax_amount")
    var taxAmount: Double

    @Field(key: "shipping_amount")
    var shippingAmount: Double

    @Field(key: "total")
    var total: Double

    @Field(key: "status")
    var status: OrderStatus

    // Square payment linkage
    @OptionalField(key: "square_payment_id")
    var squarePaymentID: String?

    @OptionalField(key: "payment_status")
    var paymentStatus: String?

    @OptionalField(key: "customer_note")
    var customerNote: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$order)
    var items: [OrderItem]

    init() { }

    init(
        id: UUID? = nil,
        orderNumber: String,
        userID: UUID? = nil,
        email: String,
        customerName: String,
        phone: String? = nil,
        shippingLine1: String,
        shippingLine2: String? = nil,
        shippingCity: String,
        shippingState: String,
        shippingPostalCode: String,
        shippingCountry: String,
        subtotal: Double,
        taxAmount: Double,
        shippingAmount: Double,
        total: Double,
        status: OrderStatus = .pendingPayment,
        squarePaymentID: String? = nil,
        paymentStatus: String? = nil,
        customerNote: String? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.$user.id = userID
        self.email = email
        self.customerName = customerName
        self.phone = phone
        self.shippingLine1 = shippingLine1
        self.shippingLine2 = shippingLine2
        self.shippingCity = shippingCity
        self.shippingState = shippingState
        self.shippingPostalCode = shippingPostalCode
        self.shippingCountry = shippingCountry
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.shippingAmount = shippingAmount
        self.total = total
        self.status = status
        self.squarePaymentID = squarePaymentID
        self.paymentStatus = paymentStatus
        self.customerNote = customerNote
    }
}

/// A single line item within an order. Captures a snapshot of the product so the
/// order record stays accurate even if the product is later edited or deleted.
final class OrderItem: Model, @unchecked Sendable {
    static let schema = "order_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: Order

    /// Null if the product was later deleted; the snapshot fields remain.
    @OptionalParent(key: "product_id")
    var product: Product?

    @Field(key: "product_name")
    var productName: String

    @OptionalField(key: "sku")
    var sku: String?

    @Field(key: "unit_price")
    var unitPrice: Double

    @Field(key: "quantity")
    var quantity: Int

    @Field(key: "line_total")
    var lineTotal: Double

    init() { }

    init(
        id: UUID? = nil,
        orderID: UUID,
        productID: UUID?,
        productName: String,
        sku: String?,
        unitPrice: Double,
        quantity: Int
    ) {
        self.id = id
        self.$order.id = orderID
        self.$product.id = productID
        self.productName = productName
        self.sku = sku
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.lineTotal = unitPrice * Double(quantity)
    }
}

// MARK: - DTOs

struct OrderItemDTO: Content {
    let id: UUID?
    let productID: UUID?
    let productName: String
    let sku: String?
    let unitPrice: Double
    let quantity: Int
    let lineTotal: Double
}

extension OrderItem {
    func toDTO() -> OrderItemDTO {
        .init(
            id: self.id,
            productID: self.$product.id,
            productName: self.productName,
            sku: self.sku,
            unitPrice: self.unitPrice,
            quantity: self.quantity,
            lineTotal: self.lineTotal
        )
    }
}

struct OrderDTO: Content {
    let id: UUID?
    let orderNumber: String
    let email: String
    let customerName: String
    let phone: String?
    let shippingLine1: String
    let shippingLine2: String?
    let shippingCity: String
    let shippingState: String
    let shippingPostalCode: String
    let shippingCountry: String
    let subtotal: Double
    let taxAmount: Double
    let shippingAmount: Double
    let total: Double
    let status: OrderStatus
    let paymentStatus: String?
    let customerNote: String?
    let items: [OrderItemDTO]
    let createdAt: Date?
}

extension Order {
    /// Builds a DTO. `items` must already be loaded (eager-loaded) by the caller.
    func toDTO() -> OrderDTO {
        .init(
            id: self.id,
            orderNumber: self.orderNumber,
            email: self.email,
            customerName: self.customerName,
            phone: self.phone,
            shippingLine1: self.shippingLine1,
            shippingLine2: self.shippingLine2,
            shippingCity: self.shippingCity,
            shippingState: self.shippingState,
            shippingPostalCode: self.shippingPostalCode,
            shippingCountry: self.shippingCountry,
            subtotal: self.subtotal,
            taxAmount: self.taxAmount,
            shippingAmount: self.shippingAmount,
            total: self.total,
            status: self.status,
            paymentStatus: self.paymentStatus,
            customerNote: self.customerNote,
            items: (self.$items.value ?? []).map { $0.toDTO() },
            createdAt: self.createdAt
        )
    }

    /// Generates a short, human-friendly order number.
    static func generateOrderNumber() -> String {
        "NY-" + String(UUID().uuidString.prefix(6)).uppercased()
    }
}

// MARK: - Request payloads

/// Shipping address supplied at checkout.
struct ShippingAddressPayload: Content {
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
}
