import Fluent
import SQLKit

/// Adds the `is_featured` column to products (defaults to false for existing rows).
struct AddProductFeatured: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("products")
            .field("is_featured", .bool, .required, .sql(.default(false)))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("products")
            .deleteField("is_featured")
            .update()
    }
}
