import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// Represents a user's favorite/wishlist item (registered users only)
final class Favorite: Model, @unchecked Sendable {
    static let schema = "favorites"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "product_id")
    var product: Product
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, productID: UUID) {
        self.id = id
        self.$user.id = userID
        self.$product.id = productID
    }
}

// MARK: - DTOs
struct FavoriteDTO: Content {
    let id: UUID?
    let product: ProductDTO
    let createdAt: Date?
}

extension Favorite {
    func toDTO() -> FavoriteDTO {
        .init(
            id: self.id,
            product: self.product.toDTO(),
            createdAt: self.createdAt
        )
    }
}

struct AddFavoriteRequest: Content {
    let productID: UUID
}

struct FavoritesListResponse: Content {
    let favorites: [FavoriteDTO]
    let count: Int
}
