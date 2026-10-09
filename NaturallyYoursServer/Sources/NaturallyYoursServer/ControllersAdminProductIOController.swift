import Vapor
import Fluent

/// Admin-only endpoints for bulk CSV import/export and per-product image upload.
struct AdminProductIOController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "admin", "products")
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())
            .grouped(ModeratorMiddleware())

        group.get(use: listAllProducts)
        group.on(.POST, "import", body: .collect(maxSize: "10mb"), use: importCSV)
        group.get("export", use: exportCSV)
        group.on(.POST, ":productID", "images", "upload", body: .collect(maxSize: "15mb"), use: uploadImage)
    }

    // MARK: - List (admin)

    /// Lists every product, including inactive ones (which the public `/api/products`
    /// endpoint hides). Optional `?active=true|false` filters by active state.
    func listAllProducts(req: Request) async throws -> [ProductDTO] {
        var query = Product.query(on: req.db).sort(\.$name)
        // Parse as an optional String so an absent `active` param means "no filter".
        // (Decoding directly as Bool yields `false` when absent, which wrongly hides
        // all active products.)
        if let raw = req.query[String.self, at: "active"] {
            let active = (raw == "true" || raw == "1")
            query = query.filter(\.$isActive == active)
        }
        return try await query.all().map { $0.toDTO() }
    }

    // MARK: - CSV import

    /// Accepts a raw CSV body (text/csv) or a multipart file field named `file`.
    func importCSV(req: Request) async throws -> ProductImporter.Result {
        let admin = try req.auth.require(Admin.self)

        let csv: String
        if let upload = try? req.content.decode(FileUploadPayload.self) {
            csv = upload.file.data.getString(at: 0, length: upload.file.data.readableBytes) ?? ""
        } else {
            let buffer = req.body.data ?? ByteBuffer()
            csv = buffer.getString(at: 0, length: buffer.readableBytes) ?? ""
        }

        guard !csv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "No CSV content provided")
        }

        let result = try await ProductImporter.importCSV(csv, on: req.db)
        req.logger.info("Admin \(admin.email) imported products: \(result.created) created, \(result.updated) updated")
        return result
    }

    // MARK: - CSV export

    func exportCSV(req: Request) async throws -> Response {
        let products = try await Product.query(on: req.db).sort(\.$name).all()
        let rows = products.map {
            (handle: $0.name.lowercased().replacingOccurrences(of: " ", with: "-"),
             name: $0.name,
             description: $0.description,
             price: $0.price,
             salePrice: $0.salePrice,
             category: $0.category,
             stockQuantity: $0.stockQuantity,
             isActive: $0.isActive,
             imageURLs: $0.imageURLs,
             sku: $0.sku,
             tags: $0.tags)
        }
        let csv = ProductCSVService.export(products: rows)

        let response = Response(status: .ok)
        response.headers.contentType = HTTPMediaType(type: "text", subType: "csv")
        response.headers.contentDisposition = .init(.attachment, filename: "products-export.csv")
        response.body = .init(string: csv)
        return response
    }

    // MARK: - Image upload

    /// Uploads an image for a product, stores it on the server's Public directory,
    /// and appends its URL to the product's `imageURLs`.
    func uploadImage(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }

        let upload = try req.content.decode(FileUploadPayload.self)
        let ext = (upload.file.extension.map { "." + $0 }) ?? imageExtension(for: upload.file.contentType)
        let filename = "\(UUID().uuidString)\(ext)"

        let directory = req.application.directory.publicDirectory + "uploads/products/"
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let fullPath = directory + filename

        try await req.fileio.writeFile(upload.file.data, at: fullPath)

        // Stored as a server-relative URL; clients prepend the API base URL.
        let publicURL = "/uploads/products/\(filename)"
        product.imageURLs.append(publicURL)
        try await product.save(on: req.db)

        req.logger.info("Admin \(admin.email) uploaded image for product: \(product.name)")
        return product.toDTO()
    }

    private func imageExtension(for contentType: HTTPMediaType?) -> String {
        guard let contentType else { return ".jpg" }
        switch (contentType.type, contentType.subType) {
        case ("image", "png"): return ".png"
        case ("image", "heic"): return ".heic"
        case ("image", "webp"): return ".webp"
        case ("image", "gif"): return ".gif"
        default: return ".jpg"
        }
    }
}

/// Multipart file upload payload (field name `file`).
struct FileUploadPayload: Content {
    var file: File
}
