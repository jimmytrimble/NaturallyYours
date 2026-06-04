//
//  AuthService.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/28/26.
//

import Foundation
import Combine

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: UserDTO?
    @Published var isAuthenticated = false
    @Published var isGuest = false
    
    // Base URL is now configured in AppConfiguration.swift
    // This automatically switches between development and production
    private var baseURL: String {
        AppConfiguration.apiBaseURL
    }
    
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = .shared
        return URLSession(configuration: config)
    }
    
    // MARK: - User Registration
    
    func signup(firstName: String, lastName: String, email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/users/signup") else {
            throw AuthError.invalidURL
        }
        
        let fullName = "\(firstName) \(lastName)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SignupRequest(
            name: fullName,
            email: email,
            password: password,
            confirmPassword: password
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.currentUser = authResponse.user
                self.isAuthenticated = true
                self.isGuest = false
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw AuthError.serverError(errorResponse?.reason ?? "Signup failed")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - User Login
    
    func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/users/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Use Basic Authentication
        let credentials = "\(email):\(password)"
            .data(using: .utf8)!
            .base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.currentUser = authResponse.user
                self.isAuthenticated = true
                self.isGuest = false
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw AuthError.serverError(errorResponse?.reason ?? "Login failed")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Logout
    
    func logout() async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/users/logout") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isGuest = false
                
                // Clear cookies
                if let cookies = HTTPCookieStorage.shared.cookies {
                    for cookie in cookies {
                        HTTPCookieStorage.shared.deleteCookie(cookie)
                    }
                }
            } else {
                throw AuthError.serverError("Logout failed")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Guest Access
    
    func continueAsGuest() {
        self.currentUser = nil
        self.isAuthenticated = false
        self.isGuest = true
    }
    
    // MARK: - Get Current User
    
    func getCurrentUser() async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/users/me") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let user = try JSONDecoder().decode(UserDTO.self, from: data)
                self.currentUser = user
                self.isAuthenticated = true
                self.isGuest = false
            } else if httpResponse.statusCode == 401 {
                // Not authenticated
                self.currentUser = nil
                self.isAuthenticated = false
                self.isGuest = false
            } else {
                throw AuthError.serverError("Failed to get current user")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
}
