//
//  HomeView.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/28/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authService: AuthService
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Welcome Message
                VStack(spacing: 12) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green.gradient)
                    
                    if authService.isGuest {
                        Text("Hello, Guest!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Welcome to Naturally Yours")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    } else if let user = authService.currentUser {
                        // Extract first name from full name
                        let firstName = user.name.components(separatedBy: " ").first ?? user.name
                        
                        Text("Hello, \(firstName)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Welcome back to Naturally Yours")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 80)
                
                Spacer()
                
                // User Info Card (if authenticated)
                if !authService.isGuest, let user = authService.currentUser {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Information")
                            .font(.headline)
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Name")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(user.name)
                                    .font(.body)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(user.email)
                                    .font(.body)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                }
                
                // Guest Info Card
                if authService.isGuest {
                    VStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        
                        Text("You're browsing as a guest")
                            .font(.headline)
                        
                        Text("Create an account to save your preferences and order history")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Logout Button
                Button {
                    Task {
                        await handleLogout()
                    }
                } label: {
                    if isLoggingOut {
                        ProgressView()
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(authService.isGuest ? "Exit Guest Mode" : "Log Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.large)
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .disabled(isLoggingOut)
            }
            .navigationTitle("Home")
        }
    }
    
    private func handleLogout() async {
        isLoggingOut = true
        
        if authService.isGuest {
            // Just reset state for guest
            authService.isGuest = false
        } else {
            // Call logout API for authenticated users
            try? await authService.logout()
        }
        
        isLoggingOut = false
    }
}

#Preview {
    // Preview with authenticated user
    let authService = AuthService()
    authService.currentUser = UserDTO(
        id: UUID(),
        name: "John Smith",
        email: "john@example.com"
    )
    authService.isAuthenticated = true
    
    return HomeView(authService: authService)
}

#Preview("Guest") {
    // Preview with guest user
    let authService = AuthService()
    authService.isGuest = true
    
    return HomeView(authService: authService)
}
