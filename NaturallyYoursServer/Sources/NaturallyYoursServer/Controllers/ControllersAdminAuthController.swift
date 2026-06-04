import Vapor
import Fluent

struct AdminAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let admins = routes.grouped("api", "auth", "admins")
        
        // Admin login (anyone can attempt to login)
        let passwordProtected = admins.grouped(Admin.authenticator())
        passwordProtected.post("login", use: login)
        
        // Protected admin routes
        let protected = admins.grouped(Admin.sessionAuthenticator())
        protected.post("logout", use: logout)
        protected.get("me", use: getCurrentAdmin)
        
        // Super admin only routes (for creating new admins)
        let superAdminProtected = protected.grouped(AdminRoleMiddleware(requiredRole: .superAdmin))
        superAdminProtected.post("create", use: createAdmin)
        superAdminProtected.get("list", use: listAdmins)
        superAdminProtected.delete(":adminID", use: deleteAdmin)
    }
    
    // MARK: - Login
    func login(req: Request) async throws -> AdminAuthResponse {
        let admin = try req.auth.require(Admin.self)
        req.session.authenticate(admin)
        
        return AdminAuthResponse(admin: admin.toDTO(), token: nil)
    }
    
    // MARK: - Logout
    func logout(req: Request) async throws -> HTTPStatus {
        req.auth.logout(Admin.self)
        req.session.unauthenticate(Admin.self)
        return .noContent
    }
    
    // MARK: - Get Current Admin
    func getCurrentAdmin(req: Request) async throws -> AdminDTO {
        let admin = try req.auth.require(Admin.self)
        return admin.toDTO()
    }
    
    // MARK: - Create Admin (Super Admin Only)
    func createAdmin(req: Request) async throws -> AdminDTO {
        try AdminSignupRequest.validate(content: req)
        let signupRequest = try req.content.decode(AdminSignupRequest.self)
        
        // Check password confirmation
        guard signupRequest.password == signupRequest.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords do not match")
        }
        
        // Check if admin already exists
        if let _ = try await Admin.query(on: req.db)
            .filter(\.$email == signupRequest.email)
            .first() {
            throw Abort(.conflict, reason: "An admin with this email already exists")
        }
        
        // Create admin
        let passwordHash = try Bcrypt.hash(signupRequest.password)
        let admin = Admin(
            name: signupRequest.name,
            email: signupRequest.email,
            passwordHash: passwordHash,
            role: signupRequest.role ?? .moderator
        )
        
        try await admin.save(on: req.db)
        
        return admin.toDTO()
    }
    
    // MARK: - List Admins (Super Admin Only)
    func listAdmins(req: Request) async throws -> [AdminDTO] {
        let admins = try await Admin.query(on: req.db).all()
        return admins.map { $0.toDTO() }
    }
    
    // MARK: - Delete Admin (Super Admin Only)
    func deleteAdmin(req: Request) async throws -> HTTPStatus {
        guard let adminID = req.parameters.get("adminID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid admin ID")
        }
        
        guard let admin = try await Admin.find(adminID, on: req.db) else {
            throw Abort(.notFound, reason: "Admin not found")
        }
        
        // Prevent deleting yourself
        let currentAdmin = try req.auth.require(Admin.self)
        if admin.id == currentAdmin.id {
            throw Abort(.badRequest, reason: "Cannot delete your own admin account")
        }
        
        try await admin.delete(on: req.db)
        return .noContent
    }
}

// MARK: - Admin Role Middleware
struct AdminRoleMiddleware: AsyncMiddleware {
    let requiredRole: AdminRole
    
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let admin = try request.auth.require(Admin.self)
        
        // Super admins can access everything
        if admin.role == .superAdmin {
            return try await next.respond(to: request)
        }
        
        // Check if admin has required role
        guard admin.role == requiredRole else {
            throw Abort(.forbidden, reason: "Insufficient permissions")
        }
        
        return try await next.respond(to: request)
    }
}


