import Foundation

// MARK: - Admin identity

enum AdminRole: String, Codable {
    case superAdmin = "super_admin"
    case moderator
    case support

    var displayName: String {
        switch self {
        case .superAdmin: return "Super Admin"
        case .moderator: return "Moderator"
        case .support: return "Support"
        }
    }

    /// Support is read-only; moderators and super admins can edit the catalog/orders.
    var canManageCatalog: Bool {
        self != .support
    }
}

struct AdminDTO: Decodable, Identifiable {
    let id: UUID?
    let name: String
    let email: String
    let role: AdminRole
    let createdAt: Date?
}

struct AdminAuthResponse: Decodable {
    let admin: AdminDTO
    let token: String?
}

// MARK: - Product admin requests

struct CreateProductRequest: Encodable {
    let name: String
    let description: String
    let price: Double
    let salePrice: Double?
    let category: String
    let stockQuantity: Int
    let imageURLs: [String]
    let sku: String?
    let weight: Double?
    let tags: [String]
}

struct UpdateProductRequest: Encodable {
    var name: String?
    var description: String?
    var price: Double?
    var salePrice: Double?
    var category: String?
    var stockQuantity: Int?
    var isActive: Bool?
    var imageURLs: [String]?
    var sku: String?
    var weight: Double?
    var tags: [String]?
}

struct UpdatePriceRequest: Encodable {
    let price: Double?
    let salePrice: Double?
}

struct UpdateStockRequest: Encodable {
    let stockQuantity: Int
}

struct UpdateImagesRequest: Encodable {
    let imageURLs: [String]
}

// MARK: - Order / messaging admin requests

struct UpdateOrderStatusRequest: Encodable {
    let status: OrderStatus
}

struct AdminConversationUpdateRequest: Encodable {
    let status: ConversationStatus?
    let assignToMe: Bool?
}

// MARK: - Bulk import result

struct ImportResult: Decodable {
    let created: Int
    let updated: Int
    let total: Int
}
