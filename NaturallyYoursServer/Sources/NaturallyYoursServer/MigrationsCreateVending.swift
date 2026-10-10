import Fluent

struct CreateVendingMachine: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("vending_machines")
            .id()
            .field("name", .string, .required)
            .field("campus", .string, .required)
            .field("location", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("vending_machines").delete()
    }
}

struct CreateVendingSlot: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("vending_slots")
            .id()
            .field("machine_id", .uuid, .required,
                   .references("vending_machines", "id", onDelete: .cascade))
            .field("slot_number", .int, .required)
            .field("product_name", .string, .required)
            .field("on_hand", .int, .required)
            .field("hold", .int, .required)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("vending_slots").delete()
    }
}
