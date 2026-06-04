import Fluent

struct CreateCart: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("carts")
            .id()
            .field("user_id", .uuid, .references("users", "id", onDelete: .cascade))
            .field("session_id", .string)
            .field("is_active", .bool, .required)
            .field("expires_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("carts").delete()
    }
}

struct CreateCartItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("cart_items")
            .id()
            .field("cart_id", .uuid, .required, .references("carts", "id", onDelete: .cascade))
            .field("product_id", .uuid, .required, .references("products", "id", onDelete: .restrict))
            .field("quantity", .int, .required)
            .field("price_at_addition", .double, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "cart_id", "product_id")  // Prevent duplicate products in same cart
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("cart_items").delete()
    }
}
