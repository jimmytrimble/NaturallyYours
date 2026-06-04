import Fluent

struct CreateProduct: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("products")
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("price", .double, .required)
            .field("sale_price", .double)
            .field("category", .string, .required)
            .field("stock_quantity", .int, .required)
            .field("is_active", .bool, .required)
            .field("image_urls", .array(of: .string), .required)
            .field("sku", .string)
            .field("weight", .double)
            .field("tags", .array(of: .string), .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("products").delete()
    }
}
