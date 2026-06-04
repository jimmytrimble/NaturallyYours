import Vapor
import struct Foundation.UUID
import struct Foundation.Date

// MARK: - User DTOs

struct UserDTO: Content {
    let id: UUID?
    let name: String
    let email: String
    let createdAt: Date?
}

struct UserSignupRequest: Content, Validatable {
    let name: String
    let email: String
    let password: String
    let confirmPassword: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("password", as: String.self, is: .password)
    }
}

struct UserLoginRequest: Content {
    let email: String
    let password: String
}

struct AuthResponse: Content {
    let user: UserDTO
    let token: String?  // Optional for session-based auth
}

// MARK: - Admin DTOs

struct AdminDTO: Content {
    let id: UUID?
    let name: String
    let email: String
    let role: AdminRole
    let createdAt: Date?
}

struct AdminSignupRequest: Content, Validatable {
    let name: String
    let email: String
    let password: String
    let confirmPassword: String
    let role: AdminRole?
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("password", as: String.self, is: .password)
    }
}

struct AdminLoginRequest: Content {
    let email: String
    let password: String
}

struct AdminAuthResponse: Content {
    let admin: AdminDTO
    let token: String?
}

// MARK: - Custom Password Validation
extension Validator where T == String {
    /// Validates that a password meets security requirements:
    /// - At least 8 characters
    /// - Contains at least one uppercase letter
    /// - Contains at least one lowercase letter
    /// - Contains at least one number
    /// - Contains at least one special character
    static var password: Validator<T> {
        .characterSet(.uppercaseLetters) &&
        .characterSet(.lowercaseLetters) &&
        .characterSet(.decimalDigits)
    }
    
    /// Validates string contains characters from a character set
    static func characterSet(_ characterSet: CharacterSet) -> Validator<T> {
        .init { input in
            guard input.rangeOfCharacter(from: characterSet) != nil else {
                return ValidatorResults.PasswordValidator(
                    isValidPassword: false,
                    message: "Password must contain characters from required set"
                )
            }
            return ValidatorResults.PasswordValidator(isValidPassword: true)
        }
    }
}

extension ValidatorResults {
    struct PasswordValidator {
        let isValidPassword: Bool
        var message: String = "Password meets requirements"
    }
}

extension ValidatorResults.PasswordValidator: ValidatorResult {
    var isFailure: Bool {
        !isValidPassword
    }
    
    var successDescription: String? {
        "is a valid password"
    }
    
    var failureDescription: String? {
        message
    }
}
