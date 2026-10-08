import Fluent

/// Creates the `orders` and `order_items` tables.
struct CreateOrder: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("orders")
            .id()
            .field("order_number", .string, .required)
            .field("user_id", .uuid, .references("users", "id", onDelete: .setNull))
            .field("email", .string, .required)
            .field("customer_name", .string, .required)
            .field("phone", .string)
            .field("shipping_line1", .string, .required)
            .field("shipping_line2", .string)
            .field("shipping_city", .string, .required)
            .field("shipping_state", .string, .required)
            .field("shipping_postal_code", .string, .required)
            .field("shipping_country", .string, .required)
            .field("subtotal", .double, .required)
            .field("tax_amount", .double, .required)
            .field("shipping_amount", .double, .required)
            .field("total", .double, .required)
            .field("status", .string, .required)
            .field("square_payment_id", .string)
            .field("payment_status", .string)
            .field("customer_note", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "order_number")
            .create()

        try await database.schema("order_items")
            .id()
            .field("order_id", .uuid, .required, .references("orders", "id", onDelete: .cascade))
            .field("product_id", .uuid, .references("products", "id", onDelete: .setNull))
            .field("product_name", .string, .required)
            .field("sku", .string)
            .field("unit_price", .double, .required)
            .field("quantity", .int, .required)
            .field("line_total", .double, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("order_items").delete()
        try await database.schema("orders").delete()
    }
}
