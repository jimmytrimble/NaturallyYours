import Fluent
import Vapor

/// Upserts products parsed from a CSV into the database. Shared by the admin
/// bulk-import endpoint and the first-run auto-seed.
enum ProductImporter {

    struct Result: Content {
        var created: Int
        var updated: Int
        var total: Int
    }

    /// Imports Shopify-format CSV text, matching existing products by SKU
    /// (falling back to name) so re-imports update rather than duplicate.
    @discardableResult
    static func importCSV(_ csv: String, on db: any Database) async throws -> Result {
        let parsed = ProductCSVService.parse(csv: csv)
        var created = 0
        var updated = 0

        for p in parsed {
            // Try to find an existing product to update.
            var existing: Product?
            if let sku = p.sku, !sku.isEmpty {
                existing = try await Product.query(on: db).filter(\.$sku == sku).first()
            }
            if existing == nil {
                existing = try await Product.query(on: db).filter(\.$name == p.name).first()
            }

            if let product = existing {
                product.name = p.name
                product.description = p.description
                product.price = p.price
                product.salePrice = p.salePrice
                product.category = p.category
                product.stockQuantity = p.stockQuantity
                product.isActive = p.isActive
                // Only overwrite images if the import actually provides some, so
                // admin-uploaded images aren't wiped by a CSV that lacks them.
                if !p.imageURLs.isEmpty {
                    product.imageURLs = p.imageURLs
                }
                product.sku = p.sku
                product.tags = p.tags
                try await product.save(on: db)
                updated += 1
            } else {
                let product = Product(
                    name: p.name,
                    description: p.description,
                    price: p.price,
                    salePrice: p.salePrice,
                    category: p.category,
                    stockQuantity: p.stockQuantity,
                    isActive: p.isActive,
                    imageURLs: p.imageURLs,
                    sku: p.sku,
                    weight: nil,
                    tags: p.tags
                )
                try await product.save(on: db)
                created += 1
            }
        }

        return Result(created: created, updated: updated, total: parsed.count)
    }

    /// On first run (empty products table), seeds from `SeedData/products.csv`
    /// in the working directory if present.
    static func seedIfNeeded(_ app: Application) async throws {
        let count = try await Product.query(on: app.db).count()
        guard count == 0 else { return }

        let path = app.directory.workingDirectory + "SeedData/products.csv"
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path),
              let csv = String(data: data, encoding: .utf8) else {
            app.logger.info("No SeedData/products.csv found; skipping product seed")
            return
        }

        let result = try await importCSV(csv, on: app.db)
        app.logger.info("Seeded products from CSV: \(result.created) created, \(result.total) total")
    }
}
