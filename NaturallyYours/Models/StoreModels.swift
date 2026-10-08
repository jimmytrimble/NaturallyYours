import Foundation

// MARK: - Pagination envelope

/// Vapor's `.paginate(for:)` response: `{ "items": [...], "metadata": { page, per, total } }`.
struct Page<Item: Decodable>: Decodable {
    let items: [Item]
    let metadata: Metadata

    struct Metadata: Decodable {
        let page: Int
        let per: Int
        let total: Int
    }
}

// MARK: - Product

/// Mirrors the server `ProductDTO` returned by the `/api/products` endpoints.
///
/// Vapor emits camelCase keys with no snake_case conversion, so property names map
/// directly. Only the fields the app needs are declared; any extra JSON keys are
/// ignored by `Decodable`.
struct CatalogProduct: Identifiable, Decodable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let salePrice: Double?
    let effectivePrice: Double
    let category: String
    let stockQuantity: Int
    let inStock: Bool
    let onSale: Bool
    let isActive: Bool
    let imageURLs: [String]
    let sku: String?
    let tags: [String]

    /// Resolved URL for the first image (handles both absolute CDN URLs and
    /// server-relative upload paths).
    var primaryImageURL: URL? {
        APIClient.shared.imageURL(for: imageURLs.first)
    }

    /// Resolved URLs for all product images.
    var resolvedImageURLs: [URL] {
        imageURLs.compactMap { APIClient.shared.imageURL(for: $0) }
    }

    var formattedPrice: String {
        String(format: "$%.2f", effectivePrice)
    }

    var formattedOriginalPrice: String {
        String(format: "$%.2f", price)
    }
}

// MARK: - Cart

struct CartDTO: Decodable {
    let id: UUID?
    let items: [CartItemDTO]
    let subtotal: Double
    let itemCount: Int

    static let empty = CartDTO(id: nil, items: [], subtotal: 0, itemCount: 0)

    var formattedSubtotal: String {
        String(format: "$%.2f", subtotal)
    }
}

struct CartItemDTO: Decodable, Identifiable {
    let id: UUID?
    let product: CatalogProduct
    let quantity: Int
    let priceAtAddition: Double
    let lineTotal: Double

    var formattedLineTotal: String {
        String(format: "$%.2f", lineTotal)
    }
}

struct AddToCartRequest: Encodable {
    let productID: UUID
    let quantity: Int
}

struct UpdateCartItemRequest: Encodable {
    let quantity: Int
}

// MARK: - Favorites

struct FavoriteDTO: Decodable, Identifiable {
    let id: UUID?
    let product: CatalogProduct
}

struct FavoritesListResponse: Decodable {
    let favorites: [FavoriteDTO]
    let count: Int
}

struct AddFavoriteRequest: Encodable {
    let productID: UUID
}

struct IsFavoriteResponse: Decodable {
    let isFavorite: Bool
    let favoriteID: UUID?
}

// MARK: - Orders

enum OrderStatus: String, Codable, CaseIterable {
    case pendingPayment = "pending_payment"
    case paid
    case fulfilled
    case cancelled
    case refunded

    var displayName: String {
        switch self {
        case .pendingPayment: return "Pending Payment"
        case .paid: return "Paid"
        case .fulfilled: return "Fulfilled"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        }
    }
}

struct OrderDTO: Decodable, Identifiable {
    let id: UUID?
    let orderNumber: String
    let email: String
    let customerName: String
    let phone: String?
    let shippingLine1: String
    let shippingLine2: String?
    let shippingCity: String
    let shippingState: String
    let shippingPostalCode: String
    let shippingCountry: String
    let subtotal: Double
    let taxAmount: Double
    let shippingAmount: Double
    let total: Double
    let status: OrderStatus
    let paymentStatus: String?
    let customerNote: String?
    let items: [OrderItemDTO]
    let createdAt: Date?

    var formattedTotal: String { String(format: "$%.2f", total) }
    var formattedSubtotal: String { String(format: "$%.2f", subtotal) }
    var formattedShipping: String { String(format: "$%.2f", shippingAmount) }
    var formattedTax: String { String(format: "$%.2f", taxAmount) }
}

struct OrderItemDTO: Decodable, Identifiable {
    let id: UUID?
    let productID: UUID?
    let productName: String
    let sku: String?
    let unitPrice: Double
    let quantity: Int
    let lineTotal: Double

    var formattedLineTotal: String { String(format: "$%.2f", lineTotal) }
    var formattedUnitPrice: String { String(format: "$%.2f", unitPrice) }
}

/// Shipping address collected at checkout (mirrors `ShippingAddressPayload`).
struct ShippingAddressPayload: Encodable {
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
}

/// Checkout body (mirrors the server `CheckoutRequest`). `sourceID` is the payment
/// token produced by the Square In-App Payments SDK.
struct CheckoutRequest: Encodable {
    let sourceID: String
    let email: String
    let customerName: String
    let phone: String?
    let shipping: ShippingAddressPayload
    let customerNote: String?
}

// MARK: - Messaging

enum MessageSenderType: String, Decodable {
    case customer
    case admin
}

enum ConversationStatus: String, Codable, CaseIterable {
    case open
    case closed
}

struct MessageDTO: Decodable, Identifiable {
    let id: UUID?
    let senderType: MessageSenderType
    let senderName: String
    let body: String
    let createdAt: Date?
}

struct ConversationDTO: Decodable, Identifiable {
    let id: UUID?
    let subject: String
    let customerName: String
    let customerEmail: String
    let status: ConversationStatus
    let hasUnreadForAdmin: Bool
    let hasUnreadForCustomer: Bool
    let lastMessageAt: Date?
    let createdAt: Date?
    let messages: [MessageDTO]
}

struct StartConversationRequest: Encodable {
    let subject: String
    let message: String
    let name: String?
    let email: String?
}

struct ConversationReplyRequest: Encodable {
    let message: String
}
