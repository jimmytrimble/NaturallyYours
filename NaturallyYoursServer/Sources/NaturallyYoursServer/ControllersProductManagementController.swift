import Vapor
import Fluent

/// Controller for managing products - includes both public and admin-protected routes
struct ProductManagementController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let products = routes.grouped("api", "products")
        
        // Public routes (anyone can view products)
        products.get(use: listProducts)
        products.get("featured", use: featuredProducts)
        products.get(":productID", use: getProduct)
        products.get("category", ":category", use: getProductsByCategory)
        products.get("search", use: searchProducts)
        
        // Admin-only routes (requires moderator or super admin)
        let adminProtected = products
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())
            .grouped(ModeratorMiddleware())
        
        adminProtected.post(use: createProduct)
        adminProtected.patch(":productID", use: updateProduct)
        adminProtected.delete(":productID", use: deleteProduct)
        adminProtected.patch(":productID", "price", use: updatePrice)
        adminProtected.patch(":productID", "stock", use: updateStock)
        adminProtected.patch(":productID", "images", use: updateImages)
        adminProtected.post(":productID", "activate", use: activateProduct)
        adminProtected.post(":productID", "deactivate", use: deactivateProduct)
        adminProtected.post(":productID", "feature", use: featureProduct)
        adminProtected.post(":productID", "unfeature", use: unfeatureProduct)
    }
    
    // MARK: - Public Routes
    
    /// List all active products with optional pagination
    func listProducts(req: Request) async throws -> Page<ProductDTO> {
        let page = try await Product.query(on: req.db)
            .filter(\.$isActive == true)
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
        
        return page.map { $0.toDTO() }
    }
    
    /// Get a single product by ID
    func getProduct(req: Request) async throws -> ProductDTO {
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        return product.toDTO()
    }
    
    /// List the active products marked as featured (for the Home "Best Sellers" rail).
    func featuredProducts(req: Request) async throws -> [ProductDTO] {
        let products = try await Product.query(on: req.db)
            .filter(\.$isFeatured == true)
            .filter(\.$isActive == true)
            .sort(\.$name)
            .all()
        return products.map { $0.toDTO() }
    }

    /// Get products by category
    func getProductsByCategory(req: Request) async throws -> [ProductDTO] {
        guard let category = req.parameters.get("category") else {
            throw Abort(.badRequest, reason: "Category is required")
        }
        
        let products = try await Product.query(on: req.db)
            .filter(\.$category == category)
            .filter(\.$isActive == true)
            .sort(\.$name)
            .all()
        
        return products.map { $0.toDTO() }
    }
    
    /// Search products by name or tags
    func searchProducts(req: Request) async throws -> [ProductDTO] {
        guard let query = req.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Search query 'q' is required")
        }
        
        let products = try await Product.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$name, .custom("ILIKE"), "%\(query)%")
                group.filter(\.$description, .custom("ILIKE"), "%\(query)%")
            }
            .filter(\.$isActive == true)
            .all()
        
        return products.map { $0.toDTO() }
    }
    
    // MARK: - Admin Routes
    
    /// Create a new product (admin only)
    func createProduct(req: Request) async throws -> Response {
        let admin = try req.auth.require(Admin.self)
        try CreateProductRequest.validate(content: req)
        let productData = try req.content.decode(CreateProductRequest.self)
        
        let product = Product(
            name: productData.name,
            description: productData.description,
            price: productData.price,
            salePrice: productData.salePrice,
            category: productData.category,
            stockQuantity: productData.stockQuantity,
            isActive: true,
            imageURLs: productData.imageURLs,
            sku: productData.sku,
            weight: productData.weight,
            tags: productData.tags
        )
        
        try await product.save(on: req.db)
        
        req.logger.info("Admin \(admin.email) created product: \(product.name)")
        
        return try await product.toDTO().encodeResponse(status: .created, for: req)
    }
    
    /// Update an existing product (admin only)
    func updateProduct(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        let updateData = try req.content.decode(UpdateProductRequest.self)
        
        if let name = updateData.name { product.name = name }
        if let description = updateData.description { product.description = description }
        if let price = updateData.price { product.price = price }
        if let salePrice = updateData.salePrice { product.salePrice = salePrice }
        if let category = updateData.category { product.category = category }
        if let stockQuantity = updateData.stockQuantity { product.stockQuantity = stockQuantity }
        if let isActive = updateData.isActive { product.isActive = isActive }
        if let isFeatured = updateData.isFeatured { product.isFeatured = isFeatured }
        if let imageURLs = updateData.imageURLs { product.imageURLs = imageURLs }
        if let sku = updateData.sku { product.sku = sku }
        if let weight = updateData.weight { product.weight = weight }
        if let tags = updateData.tags { product.tags = tags }
        
        try await product.save(on: req.db)
        
        req.logger.info("Admin \(admin.email) updated product: \(product.name)")
        
        return product.toDTO()
    }
    
    /// Delete a product (admin only)
    func deleteProduct(req: Request) async throws -> HTTPStatus {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        // Check if product is in any active carts - you may want to soft-delete instead
        let cartItemsCount = try await CartItem.query(on: req.db)
            .filter(\.$product.$id == productID)
            .count()
        
        if cartItemsCount > 0 {
            // Soft delete - just deactivate
            product.isActive = false
            try await product.save(on: req.db)
            req.logger.info("Admin \(admin.email) deactivated product (in carts): \(product.name)")
            return .ok
        }
        
        try await product.delete(on: req.db)
        req.logger.info("Admin \(admin.email) deleted product: \(product.name)")
        
        return .noContent
    }
    
    /// Update product pricing (admin only)
    func updatePrice(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        try UpdatePriceRequest.validate(content: req)
        let priceData = try req.content.decode(UpdatePriceRequest.self)
        
        if let price = priceData.price {
            product.price = price
        }
        if let salePrice = priceData.salePrice {
            product.salePrice = salePrice
        }
        
        try await product.save(on: req.db)
        
        req.logger.info("Admin \(admin.email) updated price for product: \(product.name)")
        
        return product.toDTO()
    }
    
    /// Update product stock (admin only)
    func updateStock(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        struct UpdateStockRequest: Content {
            let stockQuantity: Int
        }
        
        let stockData = try req.content.decode(UpdateStockRequest.self)
        product.stockQuantity = stockData.stockQuantity
        
        try await product.save(on: req.db)
        
        req.logger.info("Admin \(admin.email) updated stock for product: \(product.name)")
        
        return product.toDTO()
    }
    
    /// Update product images (admin only)
    func updateImages(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        struct UpdateImagesRequest: Content {
            let imageURLs: [String]
        }
        
        let imageData = try req.content.decode(UpdateImagesRequest.self)
        product.imageURLs = imageData.imageURLs
        
        try await product.save(on: req.db)
        
        req.logger.info("Admin \(admin.email) updated images for product: \(product.name)")
        
        return product.toDTO()
    }
    
    /// Activate a product (admin only)
    func activateProduct(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        product.isActive = true
        try await product.save(on: req.db)
        
        req.logger.info("Admin \(admin.email) activated product: \(product.name)")
        
        return product.toDTO()
    }
    
    /// Deactivate a product (admin only)
    func deactivateProduct(req: Request) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        product.isActive = false
        try await product.save(on: req.db)

        req.logger.info("Admin \(admin.email) deactivated product: \(product.name)")

        return product.toDTO()
    }

    /// Add a product to the featured best-sellers rail (admin only).
    func featureProduct(req: Request) async throws -> ProductDTO {
        try await setFeatured(req: req, featured: true)
    }

    /// Remove a product from the featured best-sellers rail (admin only).
    func unfeatureProduct(req: Request) async throws -> ProductDTO {
        try await setFeatured(req: req, featured: false)
    }

    private func setFeatured(req: Request, featured: Bool) async throws -> ProductDTO {
        let admin = try req.auth.require(Admin.self)
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        guard let product = try await Product.find(productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        product.isFeatured = featured
        try await product.save(on: req.db)
        req.logger.info("Admin \(admin.email) \(featured ? "featured" : "unfeatured") product: \(product.name)")
        return product.toDTO()
    }
}
