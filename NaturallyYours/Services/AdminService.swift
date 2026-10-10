import Foundation
import Observation

/// Admin-facing API: authentication plus catalog, order, and messaging management.
/// Backed by the same cookie-aware `APIClient`, so the admin session established at
/// login authorizes every subsequent admin request.
@MainActor
@Observable
final class AdminService {
    var admin: AdminDTO?
    var errorMessage: String?

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    var isAuthenticated: Bool { admin != nil }
    var canManageCatalog: Bool { admin?.role.canManageCatalog ?? false }

    // MARK: - Auth

    /// Logs in via `POST /api/auth/admins/login` (HTTP Basic).
    ///
    /// The email is normalized (trimmed + lowercased) because the server matches it
    /// case-sensitively; an auto-capitalized or space-padded entry would otherwise 401.
    func login(email: String, password: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let response: AdminAuthResponse = try await client.loginBasic(
            "/api/auth/admins/login", email: normalizedEmail, password: password
        )
        admin = response.admin
    }

    /// Restores an existing admin session via `GET /api/auth/admins/me`.
    func restoreSession() async {
        admin = try? await client.get("/api/auth/admins/me")
    }

    func logout() async {
        try? await client.sendNoContent("POST", "/api/auth/admins/logout")
        admin = nil
    }

    // MARK: - Catalog management

    func createProduct(_ request: CreateProductRequest) async throws -> CatalogProduct {
        try await client.send("POST", "/api/products", body: request)
    }

    func updateProduct(id: UUID, _ request: UpdateProductRequest) async throws -> CatalogProduct {
        try await client.send("PATCH", "/api/products/\(id.uuidString)", body: request)
    }

    func deleteProduct(id: UUID) async throws {
        try await client.sendNoContent("DELETE", "/api/products/\(id.uuidString)")
    }

    func updatePrice(id: UUID, price: Double?, salePrice: Double?) async throws -> CatalogProduct {
        try await client.send("PATCH", "/api/products/\(id.uuidString)/price",
                              body: UpdatePriceRequest(price: price, salePrice: salePrice))
    }

    func updateStock(id: UUID, stockQuantity: Int) async throws -> CatalogProduct {
        try await client.send("PATCH", "/api/products/\(id.uuidString)/stock",
                              body: UpdateStockRequest(stockQuantity: stockQuantity))
    }

    func updateImages(id: UUID, imageURLs: [String]) async throws -> CatalogProduct {
        try await client.send("PATCH", "/api/products/\(id.uuidString)/images",
                              body: UpdateImagesRequest(imageURLs: imageURLs))
    }

    func setActive(id: UUID, isActive: Bool) async throws -> CatalogProduct {
        let action = isActive ? "activate" : "deactivate"
        return try await client.send("POST", "/api/products/\(id.uuidString)/\(action)")
    }

    /// Adds/removes a product from the featured best-sellers rail.
    func setFeatured(id: UUID, featured: Bool) async throws -> CatalogProduct {
        let action = featured ? "feature" : "unfeature"
        return try await client.send("POST", "/api/products/\(id.uuidString)/\(action)")
    }

    func uploadImage(productID: UUID, data: Data, filename: String, mimeType: String) async throws -> CatalogProduct {
        try await client.uploadMultipart(
            "/api/admin/products/\(productID.uuidString)/images/upload",
            fileData: data, filename: filename, mimeType: mimeType
        )
    }

    /// Loads overview counts via `GET /api/admin/stats`.
    func loadStats() async throws -> AdminStats {
        try await client.get("/api/admin/stats")
    }

    /// Lists every product including inactive ones via `GET /api/admin/products`.
    /// Pass `active` to filter server-side.
    func loadAllProducts(active: Bool? = nil) async throws -> [CatalogProduct] {
        let query = active.map { [URLQueryItem(name: "active", value: $0 ? "true" : "false")] } ?? []
        return try await client.get("/api/admin/products", query: query)
    }

    // MARK: - Bulk CSV

    func importCSV(_ csv: String) async throws -> ImportResult {
        try await client.sendRaw("POST", "/api/admin/products/import",
                                 body: Data(csv.utf8), contentType: "text/csv")
    }

    func exportCSV() async throws -> Data {
        try await client.download("/api/admin/products/export")
    }

    // MARK: - Orders

    func loadOrders() async throws -> [OrderDTO] {
        let page: Page<OrderDTO> = try await client.get(
            "/api/admin/orders", query: [URLQueryItem(name: "per", value: "200")]
        )
        return page.items
    }

    func order(id: UUID) async throws -> OrderDTO {
        try await client.get("/api/admin/orders/\(id.uuidString)")
    }

    func updateOrderStatus(id: UUID, status: OrderStatus) async throws -> OrderDTO {
        try await client.send("PATCH", "/api/admin/orders/\(id.uuidString)/status",
                              body: UpdateOrderStatusRequest(status: status))
    }

    // MARK: - Vending machines

    func loadVendingMachines() async throws -> [VendingMachine] {
        try await client.get("/api/admin/vending/machines")
    }

    func vendingMachine(id: UUID) async throws -> VendingMachine {
        try await client.get("/api/admin/vending/machines/\(id.uuidString)")
    }

    @discardableResult
    func createVendingMachine(_ request: CreateVendingMachineRequest) async throws -> VendingMachine {
        try await client.send("POST", "/api/admin/vending/machines", body: request)
    }

    @discardableResult
    func updateVendingMachine(id: UUID, _ request: UpdateVendingMachineRequest) async throws -> VendingMachine {
        try await client.send("PATCH", "/api/admin/vending/machines/\(id.uuidString)", body: request)
    }

    func deleteVendingMachine(id: UUID) async throws {
        try await client.sendNoContent("DELETE", "/api/admin/vending/machines/\(id.uuidString)")
    }

    @discardableResult
    func addVendingSlot(machineID: UUID, _ request: CreateVendingSlotRequest) async throws -> VendingMachine {
        try await client.send("POST", "/api/admin/vending/machines/\(machineID.uuidString)/slots", body: request)
    }

    @discardableResult
    func updateVendingSlot(id: UUID, _ request: UpdateVendingSlotRequest) async throws -> VendingSlot {
        try await client.send("PATCH", "/api/admin/vending/slots/\(id.uuidString)", body: request)
    }

    func deleteVendingSlot(id: UUID) async throws {
        try await client.sendNoContent("DELETE", "/api/admin/vending/slots/\(id.uuidString)")
    }

    // MARK: - Messaging inbox

    func loadConversations(status: ConversationStatus? = nil) async throws -> [ConversationDTO] {
        let query = status.map { [URLQueryItem(name: "status", value: $0.rawValue)] } ?? []
        return try await client.get("/api/admin/conversations", query: query)
    }

    func conversation(id: UUID) async throws -> ConversationDTO {
        try await client.get("/api/admin/conversations/\(id.uuidString)")
    }

    @discardableResult
    func reply(conversationID: UUID, message: String) async throws -> ConversationDTO {
        try await client.send("POST", "/api/admin/conversations/\(conversationID.uuidString)/messages",
                              body: ConversationReplyRequest(message: message))
    }

    @discardableResult
    func updateConversation(id: UUID, status: ConversationStatus? = nil, assignToMe: Bool? = nil) async throws -> ConversationDTO {
        try await client.send("PATCH", "/api/admin/conversations/\(id.uuidString)",
                              body: AdminConversationUpdateRequest(status: status, assignToMe: assignToMe))
    }
}
