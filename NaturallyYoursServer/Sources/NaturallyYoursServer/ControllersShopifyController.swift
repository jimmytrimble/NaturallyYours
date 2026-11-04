import Vapor
import Fluent

/// Admin endpoints for the Shopify integration (Option A: Shopify is the inventory
/// source of truth). Pull syncs the catalog + stock from Shopify into the local DB
/// that the app reads.
struct ShopifyController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "admin", "shopify")
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())
            .grouped(ModeratorMiddleware())

        group.get("status", use: status)
        group.post("sync", use: sync)
    }

    /// Whether Shopify is configured on the server.
    func status(req: Request) async throws -> ShopifyStatusDTO {
        ShopifyStatusDTO(configured: ShopifyConfiguration.fromEnvironment() != nil)
    }

    /// Pulls products + inventory from Shopify and upserts them into the local catalog.
    func sync(req: Request) async throws -> ShopifySyncResult {
        guard let config = ShopifyConfiguration.fromEnvironment() else {
            throw Abort(.serviceUnavailable, reason: "Shopify is not configured")
        }
        let service = ShopifyService(config: config, client: req.client, logger: req.logger)
        let remote = try await service.fetchProducts(limit: 250)

        var created = 0, updated = 0
        for sp in remote {
            // Match by Shopify id → SKU → name
            var local = try await Product.query(on: req.db)
                .filter(\.$shopifyProductID == sp.productID).first()
            if local == nil, let sku = sp.sku, !sku.isEmpty {
                local = try await Product.query(on: req.db).filter(\.$sku == sku).first()
            }
            if local == nil {
                local = try await Product.query(on: req.db).filter(\.$name == sp.title).first()
            }

            let isNew = local == nil
            let product = local ?? Product(
                name: sp.title, description: sp.descriptionHtml, price: sp.price,
                category: sp.productType.isEmpty ? "Haircare" : sp.productType,
                stockQuantity: sp.inventoryQuantity
            )

            product.name = sp.title
            product.description = sp.descriptionHtml
            product.price = sp.price
            product.stockQuantity = sp.inventoryQuantity
            product.isActive = sp.status == "ACTIVE"
            if !sp.productType.isEmpty { product.category = sp.productType }
            if !sp.imageURLs.isEmpty { product.imageURLs = sp.imageURLs }
            if let sku = sp.sku { product.sku = sku }
            if !sp.tags.isEmpty { product.tags = sp.tags }
            product.shopifyProductID = sp.productID
            product.shopifyVariantID = sp.variantID
            product.shopifyInventoryItemID = sp.inventoryItemID

            try await product.save(on: req.db)
            if isNew { created += 1 } else { updated += 1 }
        }

        req.logger.info("Shopify sync: \(created) created, \(updated) updated (\(remote.count) fetched)")
        return ShopifySyncResult(fetched: remote.count, created: created, updated: updated)
    }
}

struct ShopifyStatusDTO: Content {
    let configured: Bool
}

struct ShopifySyncResult: Content {
    let fetched: Int
    let created: Int
    let updated: Int
}
