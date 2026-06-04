import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// Represents a shopping cart for a user or guest
final class Cart: Model, @unchecked Sendable {
    static let schema = "carts"
    
    @ID(key: .id)
    var id: UUID?
    
    // Optional user ID - null for guest carts
    @OptionalParent(key: "user_id")
    var user: User?
    
    // For guest carts, we'll use a session identifier
    @OptionalField(key: "session_id")
    var sessionID: String?
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // Expiration for guest carts (e.g., 30 days)
    @OptionalField(key: "expires_at")
    var expiresAt: Date?
    
    // Relationships
    @Children(for: \.$cart)
    var items: [CartItem]
    
    init() { }
    
    init(
        id: UUID? = nil,
        userID: UUID? = nil,
        sessionID: String? = nil,
        isActive: Bool = true,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.sessionID = sessionID
        self.isActive = isActive
        self.expiresAt = expiresAt
    }
}

// MARK: - Business Logic
extension Cart {
    /// Calculate total price of all items in cart
    func calculateTotal(on db: any Database) async throws -> Double {
        let items = try await self.$items.query(on: db).with(\.$product).all()
        return items.reduce(0.0) { total, item in
            total + (item.product.effectivePrice * Double(item.quantity))
        }
    }
    
    /// Get item count in cart
    func itemCount(on db: any Database) async throws -> Int {
        let items = try await self.$items.query(on: db).all()
        return items.reduce(0) { $0 + $1.quantity }
    }
}

// MARK: - Cart Item (Join Table between Cart and Product)
final class CartItem: Model, @unchecked Sendable {
    static let schema = "cart_items"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "cart_id")
    var cart: Cart
    
    @Parent(key: "product_id")
    var product: Product
    
    @Field(key: "quantity")
    var quantity: Int
    
    // Store the price at time of adding to cart (for price consistency)
    @Field(key: "price_at_addition")
    var priceAtAddition: Double
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        cartID: UUID,
        productID: UUID,
        quantity: Int,
        priceAtAddition: Double
    ) {
        self.id = id
        self.$cart.id = cartID
        self.$product.id = productID
        self.quantity = quantity
        self.priceAtAddition = priceAtAddition
    }
}

// MARK: - DTOs
struct CartDTO: Content {
    let id: UUID?
    let items: [CartItemDTO]
    let subtotal: Double
    let itemCount: Int
    let isActive: Bool
    let createdAt: Date?
}

struct CartItemDTO: Content {
    let id: UUID?
    let product: ProductDTO
    let quantity: Int
    let priceAtAddition: Double
    let lineTotal: Double
}

extension CartItem {
    func toDTO() -> CartItemDTO {
        .init(
            id: self.id,
            product: self.product.toDTO(),
            quantity: self.quantity,
            priceAtAddition: self.priceAtAddition,
            lineTotal: self.priceAtAddition * Double(self.quantity)
        )
    }
}

struct AddToCartRequest: Content, Validatable {
    let productID: UUID
    let quantity: Int
    
    static func validations(_ validations: inout Validations) {
        validations.add("quantity", as: Int.self, is: .range(1...99))
    }
}

struct UpdateCartItemRequest: Content, Validatable {
    let quantity: Int
    
    static func validations(_ validations: inout Validations) {
        validations.add("quantity", as: Int.self, is: .range(0...99))
    }
}
