//import Vapor
//import Fluent
//
///// Example controller showing how to protect admin routes
///// This is a placeholder for your future product management system
//struct ProductController: RouteCollection {
//    func boot(routes: any RoutesBuilder) throws {
//        let products = routes.grouped("api", "products")
//        
//        // Public routes (anyone can view products)
//        products.get(use: listProducts)
//        products.get(":productID", use: getProduct)
//        
//        // Admin-only routes (requires moderator or super admin)
//        let adminProtected = products
//            .grouped(Admin.sessionAuthenticator())
//            .grouped(ModeratorMiddleware())
//        
//        adminProtected.post(use: createProduct)
//        adminProtected.patch(":productID", use: updateProduct)
//        adminProtected.delete(":productID", use: deleteProduct)
//        
//        // Price updates (also requires moderator)
//        adminProtected.patch(":productID", "price", use: updatePrice)
//    }
//    
//    // MARK: - Public Routes
//    
//    func listProducts(req: Request) async throws -> [String] {
//        // TODO: Implement product listing
//        return ["Product 1", "Product 2", "Product 3"]
//    }
//    
//    func getProduct(req: Request) async throws -> String {
//        guard let productID = req.parameters.get("productID") else {
//            throw Abort(.badRequest)
//        }
//        // TODO: Fetch and return actual product
//        return "Product: \(productID)"
//    }
//    
//    // MARK: - Admin Routes
//    
//    func createProduct(req: Request) async throws -> HTTPStatus {
//        let admin = try req.auth.require(Admin.self)
//        req.logger.info("Admin \(admin.email) is creating a product")
//        
//        // TODO: Implement product creation
//        return .created
//    }
//    
//    func updateProduct(req: Request) async throws -> HTTPStatus {
//        let admin = try req.auth.require(Admin.self)
//        guard let productID = req.parameters.get("productID") else {
//            throw Abort(.badRequest)
//        }
//        
//        req.logger.info("Admin \(admin.email) is updating product \(productID)")
//        
//        // TODO: Implement product update
//        return .ok
//    }
//    
//    func deleteProduct(req: Request) async throws -> HTTPStatus {
//        let admin = try req.auth.require(Admin.self)
//        guard let productID = req.parameters.get("productID") else {
//            throw Abort(.badRequest)
//        }
//        
//        req.logger.info("Admin \(admin.email) is deleting product \(productID)")
//        
//        // TODO: Implement product deletion
//        return .noContent
//    }
//    
//    func updatePrice(req: Request) async throws -> HTTPStatus {
//        let admin = try req.auth.require(Admin.self)
//        guard let productID = req.parameters.get("productID") else {
//            throw Abort(.badRequest)
//        }
//        
//        req.logger.info("Admin \(admin.email) is updating price for product \(productID)")
//        
//        // TODO: Implement price update
//        return .ok
//    }
//}
//
