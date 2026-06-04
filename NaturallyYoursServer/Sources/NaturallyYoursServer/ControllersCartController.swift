import Vapor
import Fluent

/// Controller for managing shopping carts (both guest and authenticated users)
struct CartController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let carts = routes.grouped("api", "cart")
        
        // Guest cart routes (using session ID)
        carts.get(use: getCart)
        carts.post("items", use: addToCart)
        carts.patch("items", ":cartItemID", use: updateCartItem)
        carts.delete("items", ":cartItemID", use: removeFromCart)
        carts.delete("clear", use: clearCart)
        
        // Authenticated user cart routes
        let userProtected = carts
            .grouped(User.sessionAuthenticator())
            .grouped(UserAuthenticatedMiddleware())
        
        userProtected.post("merge", use: mergeGuestCart)  // Merge guest cart into user cart on login
    }
    
    // MARK: - Helper Functions
    
    /// Get or create a cart for the current session/user
    private func getOrCreateCart(req: Request) async throws -> Cart {
        // Check if user is authenticated
        if let user = req.auth.get(User.self) {
            // Try to find existing cart for user
            if let cart = try await Cart.query(on: req.db)
                .filter(\.$user.$id == user.id!)
                .filter(\.$isActive == true)
                .first() {
                return cart
            }
            
            // Create new cart for user
            let cart = Cart(userID: user.id, isActive: true)
            try await cart.save(on: req.db)
            return cart
        } else {
            // Guest user - use session ID
            let sessionID = try getOrCreateSessionID(req: req)
            
            // Try to find existing cart for session
            if let cart = try await Cart.query(on: req.db)
                .filter(\.$sessionID == sessionID)
                .filter(\.$isActive == true)
                .first() {
                return cart
            }
            
            // Create new cart for guest
            let expiresAt = Date().addingTimeInterval(30 * 24 * 60 * 60)  // 30 days
            let cart = Cart(sessionID: sessionID, isActive: true, expiresAt: expiresAt)
            try await cart.save(on: req.db)
            return cart
        }
    }
    
    /// Get or create a session ID for guest users
    private func getOrCreateSessionID(req: Request) throws -> String {
        if let sessionID = req.session.data["cart_session_id"] {
            return sessionID
        }
        
        let newSessionID = UUID().uuidString
        req.session.data["cart_session_id"] = newSessionID
        return newSessionID
    }
    
    // MARK: - Route Handlers
    
    /// Get current cart with all items
    func getCart(req: Request) async throws -> CartDTO {
        let cart = try await getOrCreateCart(req: req)
        
        let items = try await cart.$items.query(on: req.db)
            .with(\.$product)
            .all()
        
        let subtotal = items.reduce(0.0) { total, item in
            total + (item.product.effectivePrice * Double(item.quantity))
        }
        
        let itemCount = items.reduce(0) { $0 + $1.quantity }
        
        return CartDTO(
            id: cart.id,
            items: items.map { $0.toDTO() },
            subtotal: subtotal,
            itemCount: itemCount,
            isActive: cart.isActive,
            createdAt: cart.createdAt
        )
    }
    
    /// Add a product to the cart
    func addToCart(req: Request) async throws -> CartDTO {
        try AddToCartRequest.validate(content: req)
        let addData = try req.content.decode(AddToCartRequest.self)
        
        // Verify product exists and is in stock
        guard let product = try await Product.find(addData.productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        guard product.isActive else {
            throw Abort(.badRequest, reason: "Product is not available")
        }
        
        guard product.stockQuantity >= addData.quantity else {
            throw Abort(.badRequest, reason: "Not enough stock available")
        }
        
        let cart = try await getOrCreateCart(req: req)
        
        // Check if product already in cart
        if let existingItem = try await CartItem.query(on: req.db)
            .filter(\.$cart.$id == cart.id!)
            .filter(\.$product.$id == product.id!)
            .first() {
            
            // Update quantity
            existingItem.quantity += addData.quantity
            
            // Verify total quantity doesn't exceed stock
            guard existingItem.quantity <= product.stockQuantity else {
                throw Abort(.badRequest, reason: "Not enough stock available")
            }
            
            try await existingItem.save(on: req.db)
        } else {
            // Create new cart item
            let cartItem = CartItem(
                cartID: cart.id!,
                productID: product.id!,
                quantity: addData.quantity,
                priceAtAddition: product.effectivePrice
            )
            try await cartItem.save(on: req.db)
        }
        
        req.logger.info("Added product \(product.name) to cart")
        
        return try await getCart(req: req)
    }
    
    /// Update quantity of a cart item
    func updateCartItem(req: Request) async throws -> CartDTO {
        guard let cartItemID = req.parameters.get("cartItemID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid cart item ID")
        }
        
        try UpdateCartItemRequest.validate(content: req)
        let updateData = try req.content.decode(UpdateCartItemRequest.self)
        
        guard let cartItem = try await CartItem.query(on: req.db)
            .filter(\.$id == cartItemID)
            .with(\.$product)
            .with(\.$cart)
            .first() else {
            throw Abort(.notFound, reason: "Cart item not found")
        }
        
        // Verify this cart belongs to current user/session
        let currentCart = try await getOrCreateCart(req: req)
        guard cartItem.cart.id == currentCart.id else {
            throw Abort(.forbidden, reason: "This cart item does not belong to you")
        }
        
        // If quantity is 0, delete the item
        if updateData.quantity == 0 {
            try await cartItem.delete(on: req.db)
            req.logger.info("Removed product \(cartItem.product.name) from cart")
        } else {
            // Verify stock availability
            guard updateData.quantity <= cartItem.product.stockQuantity else {
                throw Abort(.badRequest, reason: "Not enough stock available")
            }
            
            cartItem.quantity = updateData.quantity
            try await cartItem.save(on: req.db)
            req.logger.info("Updated quantity for product \(cartItem.product.name) in cart")
        }
        
        return try await getCart(req: req)
    }
    
    /// Remove an item from the cart
    func removeFromCart(req: Request) async throws -> HTTPStatus {
        guard let cartItemID = req.parameters.get("cartItemID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid cart item ID")
        }
        
        guard let cartItem = try await CartItem.query(on: req.db)
            .filter(\.$id == cartItemID)
            .with(\.$cart)
            .with(\.$product)
            .first() else {
            throw Abort(.notFound, reason: "Cart item not found")
        }
        
        // Verify this cart belongs to current user/session
        let currentCart = try await getOrCreateCart(req: req)
        guard cartItem.cart.id == currentCart.id else {
            throw Abort(.forbidden, reason: "This cart item does not belong to you")
        }
        
        try await cartItem.delete(on: req.db)
        req.logger.info("Removed product \(cartItem.product.name) from cart")
        
        return .noContent
    }
    
    /// Clear all items from the cart
    func clearCart(req: Request) async throws -> HTTPStatus {
        let cart = try await getOrCreateCart(req: req)
        
        try await CartItem.query(on: req.db)
            .filter(\.$cart.$id == cart.id!)
            .delete()
        
        req.logger.info("Cleared cart")
        
        return .noContent
    }
    
    /// Merge guest cart into user cart upon login
    func mergeGuestCart(req: Request) async throws -> CartDTO {
        let user = try req.auth.require(User.self)
        
        struct MergeCartRequest: Content {
            let guestSessionID: String
        }
        
        let mergeData = try req.content.decode(MergeCartRequest.self)
        
        // Find guest cart
        guard let guestCart = try await Cart.query(on: req.db)
            .filter(\.$sessionID == mergeData.guestSessionID)
            .filter(\.$isActive == true)
            .first() else {
            // No guest cart to merge, just return user's cart
            return try await getCart(req: req)
        }
        
        // Get or create user cart
        let userCart = try await getOrCreateCart(req: req)
        
        // Get all items from guest cart
        let guestItems = try await guestCart.$items.query(on: req.db)
            .with(\.$product)
            .all()
        
        // Merge items into user cart
        for guestItem in guestItems {
            // Check if product already in user cart
            if let existingItem = try await CartItem.query(on: req.db)
                .filter(\.$cart.$id == userCart.id!)
                .filter(\.$product.$id == guestItem.$product.id)
                .first() {
                
                // Update quantity
                existingItem.quantity += guestItem.quantity
                try await existingItem.save(on: req.db)
            } else {
                // Move item to user cart
                guestItem.$cart.id = userCart.id!
                try await guestItem.save(on: req.db)
            }
        }
        
        // Deactivate guest cart
        guestCart.isActive = false
        try await guestCart.save(on: req.db)
        
        req.logger.info("Merged guest cart into user cart for user: \(user.email)")
        
        return try await getCart(req: req)
    }
}

// MARK: - Middleware for User Authentication
struct UserAuthenticatedMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard request.auth.has(User.self) else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        return try await next.respond(to: request)
    }
}
