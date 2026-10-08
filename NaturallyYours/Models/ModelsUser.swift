import Foundation

// MARK: - User Models

struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"
    }
}

// MARK: - Request DTOs

struct SignupRequest: Codable {
    let name: String
    let email: String
    let password: String
    let confirmPassword: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Response DTOs

struct AuthResponse: Codable {
    let user: UserDTO
    /// Present only for token-based auth; nil for the session-cookie flow the app uses.
    let token: String?
}

struct UserDTO: Codable {
    let id: UUID
    let name: String
    let email: String

    init(id: UUID, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

struct ErrorResponse: Codable {
    let error: Bool
    let reason: String
}
