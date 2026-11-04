import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// Represents a product in the e-commerce store
final class Product: Model, @unchecked Sendable {
    static let schema = "products"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "price")
    var price: Double
    
    @OptionalField(key: "sale_price")
    var salePrice: Double?
    
    @Field(key: "category")
    var category: String
    
    @Field(key: "stock_quantity")
    var stockQuantity: Int
    
    @Field(key: "is_active")
    var isActive: Bool

    /// Whether the product is highlighted in the "Featured Best Sellers" rail.
    @Field(key: "is_featured")
    var isFeatured: Bool

    // Product images stored as an array of URLs
    @Field(key: "image_urls")
    var imageURLs: [String]
    
    // Optional fields for better e-commerce features
    @OptionalField(key: "sku")
    var sku: String?
    
    @OptionalField(key: "weight")
    var weight: Double?
    
    @Field(key: "tags")
    var tags: [String]

    // MARK: - Shopify linkage (Option A: Shopify is the inventory source of truth)
    /// Shopify product GID (e.g. "gid://shopify/Product/123"). Null for app-only items.
    @OptionalField(key: "shopify_product_id")
    var shopifyProductID: String?

    /// Default variant GID used for price/inventory operations.
    @OptionalField(key: "shopify_variant_id")
    var shopifyVariantID: String?

    /// Inventory item GID for the default variant (used to set stock levels).
    @OptionalField(key: "shopify_inventory_item_id")
    var shopifyInventoryItemID: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // Relationships
    @Children(for: \.$product)
    var cartItems: [CartItem]
    
    @Siblings(through: Favorite.self, from: \.$product, to: \.$user)
    var favoritedByUsers: [User]
    
    init() { }
    
    init(
        id: UUID? = nil,
        name: String,
        description: String,
        price: Double,
        salePrice: Double? = nil,
        category: String,
        stockQuantity: Int,
        isActive: Bool = true,
        isFeatured: Bool = false,
        imageURLs: [String] = [],
        sku: String? = nil,
        weight: Double? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.salePrice = salePrice
        self.category = category
        self.stockQuantity = stockQuantity
        self.isActive = isActive
        self.isFeatured = isFeatured
        self.imageURLs = imageURLs
        self.sku = sku
        self.weight = weight
        self.tags = tags
    }
}

// MARK: - Computed Properties
extension Product {
    /// The effective price (sale price if available, otherwise regular price)
    var effectivePrice: Double {
        salePrice ?? price
    }
    
    /// Whether the product is in stock
    var inStock: Bool {
        stockQuantity > 0
    }
    
    /// Whether the product is on sale
    var onSale: Bool {
        salePrice != nil && salePrice! < price
    }
}

// MARK: - DTO Conversion
extension Product {
    func toDTO() -> ProductDTO {
        .init(
            id: self.id,
            name: self.name,
            description: self.description,
            price: self.price,
            salePrice: self.salePrice,
            effectivePrice: self.effectivePrice,
            category: self.category,
            stockQuantity: self.stockQuantity,
            inStock: self.inStock,
            onSale: self.onSale,
            isActive: self.isActive,
            isFeatured: self.isFeatured,
            imageURLs: self.imageURLs,
            sku: self.sku,
            weight: self.weight,
            tags: self.tags,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}

// MARK: - DTOs
struct ProductDTO: Content {
    let id: UUID?
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
    let isFeatured: Bool
    let imageURLs: [String]
    let sku: String?
    let weight: Double?
    let tags: [String]
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateProductRequest: Content, Validatable {
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
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...200))
        validations.add("description", as: String.self, is: !.empty)
        validations.add("price", as: Double.self, is: .range(0.01...))
        validations.add("stockQuantity", as: Int.self, is: .range(0...))
        validations.add("category", as: String.self, is: !.empty)
    }
}

struct UpdateProductRequest: Content {
    let name: String?
    let description: String?
    let price: Double?
    let salePrice: Double?
    let category: String?
    let stockQuantity: Int?
    let isActive: Bool?
    let isFeatured: Bool?
    let imageURLs: [String]?
    let sku: String?
    let weight: Double?
    let tags: [String]?
}

struct UpdatePriceRequest: Content, Validatable {
    let price: Double?
    let salePrice: Double?
    
    static func validations(_ validations: inout Validations) {
        validations.add("price", as: Double.self, is: .range(0.01...), required: false)
        validations.add("salePrice", as: Double.self, is: .range(0.01...), required: false)
    }
}
