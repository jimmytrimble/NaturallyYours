import Vapor
import Fluent

/// Controller for managing user favorites/wishlist (authenticated users only)
struct FavoritesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let favorites = routes.grouped("api", "favorites")
        
        // All favorites routes require authentication
        let userProtected = favorites
            .grouped(User.sessionAuthenticator())
            .grouped(UserAuthenticatedMiddleware())
        
        userProtected.get(use: listFavorites)
        userProtected.post(use: addFavorite)
        userProtected.delete(":favoriteID", use: removeFavorite)
        userProtected.delete("product", ":productID", use: removeFavoriteByProduct)
        userProtected.get("check", ":productID", use: isFavorite)
    }
    
    // MARK: - Route Handlers
    
    /// Get all favorites for the authenticated user
    func listFavorites(req: Request) async throws -> FavoritesListResponse {
        let user = try req.auth.require(User.self)
        
        let favorites = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .with(\.$product)
            .sort(\.$createdAt, .descending)
            .all()
        
        return FavoritesListResponse(
            favorites: favorites.map { $0.toDTO() },
            count: favorites.count
        )
    }
    
    /// Add a product to favorites
    func addFavorite(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let favoriteData = try req.content.decode(AddFavoriteRequest.self)
        
        // Verify product exists
        guard let product = try await Product.find(favoriteData.productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        // Check if already favorited
        let existingFavorite = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$product.$id == product.id!)
            .first()
        
        if existingFavorite != nil {
            throw Abort(.conflict, reason: "Product is already in favorites")
        }
        
        // Create favorite
        let favorite = Favorite(userID: user.id!, productID: product.id!)
        try await favorite.save(on: req.db)
        
        // Load product relationship for response
        try await favorite.$product.load(on: req.db)
        
        req.logger.info("User \(user.email) added product \(product.name) to favorites")
        
        return try await favorite.toDTO().encodeResponse(status: .created, for: req)
    }
    
    /// Remove a favorite by favorite ID
    func removeFavorite(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let favoriteID = req.parameters.get("favoriteID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid favorite ID")
        }
        
        guard let favorite = try await Favorite.query(on: req.db)
            .filter(\.$id == favoriteID)
            .filter(\.$user.$id == user.id!)
            .with(\.$product)
            .first() else {
            throw Abort(.notFound, reason: "Favorite not found")
        }
        
        try await favorite.delete(on: req.db)
        
        req.logger.info("User \(user.email) removed product \(favorite.product.name) from favorites")
        
        return .noContent
    }
    
    /// Remove a favorite by product ID (convenience method)
    func removeFavoriteByProduct(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        guard let favorite = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$product.$id == productID)
            .first() else {
            throw Abort(.notFound, reason: "Product not in favorites")
        }
        
        try await favorite.delete(on: req.db)
        
        req.logger.info("User \(user.email) removed product from favorites")
        
        return .noContent
    }
    
    /// Check if a product is in the user's favorites
    func isFavorite(req: Request) async throws -> IsFavoriteResponse {
        let user = try req.auth.require(User.self)
        
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }
        
        let favorite = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$product.$id == productID)
            .first()
        
        return IsFavoriteResponse(
            isFavorite: favorite != nil,
            favoriteID: favorite?.id
        )
    }
}

// MARK: - Response DTOs
struct IsFavoriteResponse: Content {
    let isFavorite: Bool
    let favoriteID: UUID?
}
