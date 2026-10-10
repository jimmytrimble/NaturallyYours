import Vapor
import Fluent

/// Admin-only management of vending-machine inventory across campuses — tracked
/// separately from the storefront catalog.
struct VendingController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Any authenticated admin can view.
        let vending = routes.grouped("api", "admin", "vending")
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())

        vending.get("machines", use: listMachines)
        vending.get("machines", ":machineID", use: getMachine)

        // Writes require moderator/super admin (same bar as catalog management).
        let manage = vending.grouped(ModeratorMiddleware())
        manage.post("machines", use: createMachine)
        manage.patch("machines", ":machineID", use: updateMachine)
        manage.delete("machines", ":machineID", use: deleteMachine)
        manage.post("machines", ":machineID", "slots", use: createSlot)
        manage.patch("slots", ":slotID", use: updateSlot)
        manage.delete("slots", ":slotID", use: deleteSlot)
    }

    // MARK: - Machines

    func listMachines(req: Request) async throws -> [VendingMachineDTO] {
        let machines = try await VendingMachine.query(on: req.db)
            .with(\.$slots)
            .sort(\.$campus)
            .sort(\.$name)
            .all()
        return machines.map { $0.toDTO() }
    }

    func getMachine(req: Request) async throws -> VendingMachineDTO {
        let machine = try await requireMachine(req)
        try await machine.$slots.load(on: req.db)
        return machine.toDTO(includeSlots: true)
    }

    func createMachine(req: Request) async throws -> VendingMachineDTO {
        let data = try req.content.decode(CreateVendingMachineRequest.self)
        guard !data.name.trimmingCharacters(in: .whitespaces).isEmpty,
              !data.campus.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw Abort(.badRequest, reason: "Name and campus are required")
        }
        let machine = VendingMachine(name: data.name, campus: data.campus, location: data.location)
        try await machine.save(on: req.db)
        return machine.toDTO(includeSlots: true)
    }

    func updateMachine(req: Request) async throws -> VendingMachineDTO {
        let machine = try await requireMachine(req)
        let data = try req.content.decode(UpdateVendingMachineRequest.self)
        if let name = data.name { machine.name = name }
        if let campus = data.campus { machine.campus = campus }
        if let location = data.location { machine.location = location }
        try await machine.save(on: req.db)
        try await machine.$slots.load(on: req.db)
        return machine.toDTO(includeSlots: true)
    }

    func deleteMachine(req: Request) async throws -> HTTPStatus {
        let machine = try await requireMachine(req)
        try await machine.$slots.query(on: req.db).delete()
        try await machine.delete(on: req.db)
        return .noContent
    }

    // MARK: - Slots

    func createSlot(req: Request) async throws -> VendingMachineDTO {
        let machine = try await requireMachine(req)
        let data = try req.content.decode(CreateVendingSlotRequest.self)
        let slot = VendingSlot(
            machineID: try machine.requireID(),
            slotNumber: data.slotNumber,
            productName: data.productName,
            onHand: data.onHand,
            hold: data.hold
        )
        try await slot.save(on: req.db)
        try await machine.$slots.load(on: req.db)
        return machine.toDTO(includeSlots: true)
    }

    func updateSlot(req: Request) async throws -> VendingSlotDTO {
        guard let slotID = req.parameters.get("slotID", as: UUID.self),
              let slot = try await VendingSlot.find(slotID, on: req.db) else {
            throw Abort(.notFound, reason: "Slot not found")
        }
        let data = try req.content.decode(UpdateVendingSlotRequest.self)
        if let n = data.slotNumber { slot.slotNumber = n }
        if let p = data.productName { slot.productName = p }
        if let o = data.onHand { slot.onHand = max(0, o) }
        if let h = data.hold { slot.hold = max(0, h) }
        try await slot.save(on: req.db)
        return slot.toDTO()
    }

    func deleteSlot(req: Request) async throws -> HTTPStatus {
        guard let slotID = req.parameters.get("slotID", as: UUID.self),
              let slot = try await VendingSlot.find(slotID, on: req.db) else {
            throw Abort(.notFound, reason: "Slot not found")
        }
        try await slot.delete(on: req.db)
        return .noContent
    }

    // MARK: - Helpers

    private func requireMachine(_ req: Request) async throws -> VendingMachine {
        guard let id = req.parameters.get("machineID", as: UUID.self),
              let machine = try await VendingMachine.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Vending machine not found")
        }
        return machine
    }
}
