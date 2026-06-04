import Vapor
import Fluent

/// Middleware to ensure admin is authenticated
struct AdminAuthenticatedMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard request.auth.has(Admin.self) else {
            throw Abort(.unauthorized, reason: "Admin authentication required")
        }
        return try await next.respond(to: request)
    }
}

/// Middleware to ensure admin has moderator or super admin privileges
struct ModeratorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let admin = try request.auth.require(Admin.self)
        
        guard admin.role == .moderator || admin.role == .superAdmin else {
            throw Abort(.forbidden, reason: "Moderator or Super Admin privileges required")
        }
        
        return try await next.respond(to: request)
    }
}

/// Middleware to ensure admin has super admin privileges
struct SuperAdminMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let admin = try request.auth.require(Admin.self)
        
        guard admin.role == .superAdmin else {
            throw Abort(.forbidden, reason: "Super Admin privileges required")
        }
        
        return try await next.respond(to: request)
    }
}
