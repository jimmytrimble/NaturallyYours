import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// Represents a customer user in the system
final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

// MARK: - Authentication
extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, FieldProperty<User, String>> {
        \User.$email
    }
    
    static var passwordHashKey: KeyPath<User, FieldProperty<User, String>> {
        \User.$passwordHash
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// MARK: - Session Authentication
extension User: ModelSessionAuthenticatable { }

// MARK: - DTO Conversion
extension User {
    func toDTO() -> UserDTO {
        .init(
            id: self.id,
            name: self.name,
            email: self.email,
            createdAt: self.createdAt
        )
    }
}
