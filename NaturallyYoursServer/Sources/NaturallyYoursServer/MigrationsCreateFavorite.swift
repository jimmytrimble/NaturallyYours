import Fluent

struct CreateFavorite: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("favorites")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("product_id", .uuid, .required, .references("products", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "user_id", "product_id")  // Prevent duplicate favorites
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("favorites").delete()
    }
}
