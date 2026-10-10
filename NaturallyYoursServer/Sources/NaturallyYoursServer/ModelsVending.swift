import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// A vending machine at a campus/location. Holds numbered slots of products, tracked
/// separately from the storefront catalog.
final class VendingMachine: Model, @unchecked Sendable {
    static let schema = "vending_machines"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String
    @Field(key: "campus") var campus: String
    @OptionalField(key: "location") var location: String?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$machine) var slots: [VendingSlot]

    init() {}

    init(id: UUID? = nil, name: String, campus: String, location: String? = nil) {
        self.id = id
        self.name = name
        self.campus = campus
        self.location = location
    }
}

/// One numbered slot within a vending machine: a product with its on-hand count and
/// a "hold" (par/target) level.
final class VendingSlot: Model, @unchecked Sendable {
    static let schema = "vending_slots"

    @ID(key: .id) var id: UUID?

    @Parent(key: "machine_id") var machine: VendingMachine

    @Field(key: "slot_number") var slotNumber: Int
    @Field(key: "product_name") var productName: String
    @Field(key: "on_hand") var onHand: Int
    @Field(key: "hold") var hold: Int

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, machineID: UUID, slotNumber: Int, productName: String, onHand: Int, hold: Int) {
        self.id = id
        self.$machine.id = machineID
        self.slotNumber = slotNumber
        self.productName = productName
        self.onHand = onHand
        self.hold = hold
    }
}

// MARK: - DTOs

struct VendingSlotDTO: Content {
    let id: UUID?
    let slotNumber: Int
    let productName: String
    let onHand: Int
    let hold: Int
}

extension VendingSlot {
    func toDTO() -> VendingSlotDTO {
        .init(id: id, slotNumber: slotNumber, productName: productName, onHand: onHand, hold: hold)
    }
}

struct VendingMachineDTO: Content {
    let id: UUID?
    let name: String
    let campus: String
    let location: String?
    let slotCount: Int
    /// Slots that are empty or nearly empty (on hand <= 2).
    let needsRestockCount: Int
    /// Included when a single machine is fetched; empty in list views.
    let slots: [VendingSlotDTO]
}

extension VendingMachine {
    func toDTO(includeSlots: Bool = false) -> VendingMachineDTO {
        let loaded = self.$slots.value ?? []
        return .init(
            id: id,
            name: name,
            campus: campus,
            location: location,
            slotCount: loaded.count,
            needsRestockCount: loaded.filter { $0.onHand <= 2 }.count,
            slots: includeSlots
                ? loaded.sorted { $0.slotNumber < $1.slotNumber }.map { $0.toDTO() }
                : []
        )
    }
}

// MARK: - Request payloads

struct CreateVendingMachineRequest: Content {
    let name: String
    let campus: String
    let location: String?
}

struct UpdateVendingMachineRequest: Content {
    let name: String?
    let campus: String?
    let location: String?
}

struct CreateVendingSlotRequest: Content {
    let slotNumber: Int
    let productName: String
    let onHand: Int
    let hold: Int
}

struct UpdateVendingSlotRequest: Content {
    let slotNumber: Int?
    let productName: String?
    let onHand: Int?
    let hold: Int?
}
