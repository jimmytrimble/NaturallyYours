import Fluent

/// Adds Shopify linkage columns to the products table so local products can map to
/// their Shopify counterparts (Option A: Shopify as the inventory source of truth).
struct AddShopifyFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("products")
            .field("shopify_product_id", .string)
            .field("shopify_variant_id", .string)
            .field("shopify_inventory_item_id", .string)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("products")
            .deleteField("shopify_product_id")
            .deleteField("shopify_variant_id")
            .deleteField("shopify_inventory_item_id")
            .update()
    }
}
