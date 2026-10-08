import Fluent

/// Creates the `conversations` and `messages` tables for the in-app contact system.
struct CreateMessaging: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("conversations")
            .id()
            .field("subject", .string, .required)
            .field("user_id", .uuid, .references("users", "id", onDelete: .setNull))
            .field("session_id", .string)
            .field("customer_name", .string, .required)
            .field("customer_email", .string, .required)
            .field("status", .string, .required)
            .field("assigned_admin_id", .uuid, .references("admins", "id", onDelete: .setNull))
            .field("has_unread_for_admin", .bool, .required)
            .field("has_unread_for_customer", .bool, .required)
            .field("last_message_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()

        try await database.schema("messages")
            .id()
            .field("conversation_id", .uuid, .required, .references("conversations", "id", onDelete: .cascade))
            .field("sender_type", .string, .required)
            .field("sender_name", .string, .required)
            .field("sender_user_id", .uuid, .references("users", "id", onDelete: .setNull))
            .field("sender_admin_id", .uuid, .references("admins", "id", onDelete: .setNull))
            .field("body", .string, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("messages").delete()
        try await database.schema("conversations").delete()
    }
}
