import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// Represents an admin user with elevated privileges
final class Admin: Model, @unchecked Sendable {
    static let schema = "admins"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Enum(key: "role")
    var role: AdminRole
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, name: String, email: String, passwordHash: String, role: AdminRole = .moderator) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
    }
}

// MARK: - Admin Roles
enum AdminRole: String, Codable, Sendable {
    case superAdmin = "super_admin"  // Full access to everything
    case moderator = "moderator"      // Can edit products and prices
    case support = "support"          // Read-only access for customer support
}

// MARK: - Authentication
extension Admin: ModelAuthenticatable {
    static var usernameKey: KeyPath<Admin, FieldProperty<Admin, String>> {
        \Admin.$email
    }
    
    static var passwordHashKey: KeyPath<Admin, FieldProperty<Admin, String>> {
        \Admin.$passwordHash
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// MARK: - Session Authentication
extension Admin: ModelSessionAuthenticatable { }

// MARK: - DTO Conversion
extension Admin {
    func toDTO() -> AdminDTO {
        .init(
            id: self.id,
            name: self.name,
            email: self.email,
            role: self.role,
            createdAt: self.createdAt
        )
    }
}
