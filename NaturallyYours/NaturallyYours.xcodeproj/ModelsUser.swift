////
////  User.swift
////  NaturallyYours
////
////  Created by Jamiel Trimble II on 5/28/26.
////
//
//import Foundation
//
//// MARK: - User Models
//
//struct User: Codable, Identifiable {
//    let id: UUID
//    let name: String
//    let email: String
//    let createdAt: Date?
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case name
//        case email
//        case createdAt = "created_at"
//    }
//}
//
//// MARK: - Request DTOs
//
//struct SignupRequest: Codable {
//    let name: String
//    let email: String
//    let password: String
//    let confirmPassword: String
//}
//
//struct LoginRequest: Codable {
//    let email: String
//    let password: String
//}
//
//// MARK: - Response DTOs
//
//struct AuthResponse: Codable {
//    let user: UserDTO
//    let message: String
//}
//
//struct UserDTO: Codable {
//    let id: UUID
//    let name: String
//    let email: String
//}
//
//struct ErrorResponse: Codable {
//    let error: Bool
//    let reason: String
//}
