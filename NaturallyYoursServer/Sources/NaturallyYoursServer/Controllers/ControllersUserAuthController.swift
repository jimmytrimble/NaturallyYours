import Vapor
import Fluent

struct UserAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "auth", "users")
        
        // Public routes
        users.post("signup", use: signup)
        
        let passwordProtected = users.grouped(User.authenticator())
        passwordProtected.post("login", use: login)
        
        // Protected routes (requires authentication)
        let protected = users.grouped(User.sessionAuthenticator())
        protected.post("logout", use: logout)
        protected.get("me", use: getCurrentUser)
    }
    
    // MARK: - Signup
    func signup(req: Request) async throws -> AuthResponse {
        // Validate input
        try UserSignupRequest.validate(content: req)
        let signupRequest = try req.content.decode(UserSignupRequest.self)
        
        // Check password confirmation
        guard signupRequest.password == signupRequest.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords do not match")
        }
        
        // Check if user already exists
        if let _ = try await User.query(on: req.db)
            .filter(\.$email == signupRequest.email)
            .first() {
            throw Abort(.conflict, reason: "A user with this email already exists")
        }
        
        // Create user
        let passwordHash = try Bcrypt.hash(signupRequest.password)
        let user = User(
            name: signupRequest.name,
            email: signupRequest.email,
            passwordHash: passwordHash
        )
        
        try await user.save(on: req.db)
        
        // Log user in
        req.auth.login(user)
        req.session.authenticate(user)
        
        // Create response with the saved user data
        let userDTO = UserDTO(
            id: user.id,
            name: user.name,
            email: user.email,
            createdAt: user.createdAt
        )
        
        req.logger.info("User created successfully: \(user.email)")
        
        return AuthResponse(user: userDTO, token: nil)
    }
    
    // MARK: - Login
    func login(req: Request) async throws -> AuthResponse {
        let user = try req.auth.require(User.self)
        req.session.authenticate(user)
        
        return AuthResponse(user: user.toDTO(), token: nil)
    }
    
    // MARK: - Logout
    func logout(req: Request) async throws -> HTTPStatus {
        req.auth.logout(User.self)
        req.session.unauthenticate(User.self)
        return .noContent
    }
    
    // MARK: - Get Current User
    func getCurrentUser(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        return user.toDTO()
    }
}

// MARK: - Guest Checkout
struct GuestCheckoutController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let guest = routes.grouped("api", "guest")
        guest.post("checkout", use: guestCheckout)
    }
    
    func guestCheckout(req: Request) async throws -> GuestOrderResponse {
        let checkoutRequest = try req.content.decode(GuestCheckoutRequest.self)
        
        // Validate email
        guard checkoutRequest.email.contains("@") else {
            throw Abort(.badRequest, reason: "Invalid email address")
        }
        
        // Process guest checkout
        // You'll implement order creation logic here
        
        return GuestOrderResponse(
            orderId: UUID(),
            email: checkoutRequest.email,
            message: "Order placed successfully. A confirmation email has been sent."
        )
    }
}

struct GuestCheckoutRequest: Content {
    let email: String
    let name: String?
    // Add cart items, shipping address, payment info, etc.
}

struct GuestOrderResponse: Content {
    let orderId: UUID
    let email: String
    let message: String
}
