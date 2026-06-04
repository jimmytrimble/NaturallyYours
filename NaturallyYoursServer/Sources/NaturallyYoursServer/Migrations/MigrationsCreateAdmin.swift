import Fluent

struct CreateAdmin: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let roleEnum = try await database.enum("admin_role")
            .case("super_admin")
            .case("moderator")
            .case("support")
            .create()
        
        try await database.schema("admins")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("role", roleEnum, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("admins").delete()
        try await database.enum("admin_role").delete()
    }
}
