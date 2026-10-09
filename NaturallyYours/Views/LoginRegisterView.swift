import SwiftUI
import Combine

struct LoginRegisterView: View {
    @StateObject private var authService = AuthService()
    @State private var isShowingRegister = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated || authService.isGuest {
                MainTabView(authService: authService)
            } else {
                if isShowingRegister {
                    RegisterView(authService: authService, isShowingRegister: $isShowingRegister)
                } else {
                    LoginView(authService: authService, isShowingRegister: $isShowingRegister)
                }
            }
        }
        .task {
            // Check if user is already logged in
            try? await authService.getCurrentUser()
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @ObservedObject var authService: AuthService
    @Binding var isShowingRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.nySoftPink.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                    loginForm
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .alert("Login Failed", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            Image("login_hero")
                .resizable()
                .scaledToFill()
                .frame(height: 400)
                .frame(maxWidth: .infinity)
                .clipped()
                // Feather both the top and bottom edges so the photo melts into the
                // soft-pink background instead of ending on a hard rectangle.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.20),
                            .init(color: .black, location: 0.66),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 4) {
                Text("Naturally Yours")
                    .font(.custom("Zapfino", size: 34))
                    .foregroundStyle(.nyBlack)

                Text("BEAUTY SUPPLY")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .tracking(5)
                    .foregroundStyle(.nyBlack.opacity(0.65))
            }
            .padding(.bottom, 28)
        }
        .frame(height: 400)
    }

    // MARK: - Form

    private var loginForm: some View {
        VStack(spacing: 18) {
            VStack(spacing: 3) {
                Text("Welcome back")
                    .font(.system(size: 27, weight: .regular, design: .serif))
                    .foregroundStyle(.nyBlack)
                Text("Sign in to continue")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(.nyGray)
            }
            .padding(.bottom, 4)

            VStack(spacing: 14) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(fieldBackground)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(fieldBackground)
            }

            Button {
                Task { await handleLogin() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Log In").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nyPink)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.nyGray.opacity(0.3))
                Text("or").font(.nyCaption(13)).foregroundStyle(.nyGray)
                Rectangle().frame(height: 1).foregroundStyle(.nyGray.opacity(0.3))
            }
            .padding(.vertical, 2)

            Button {
                authService.continueAsGuest()
            } label: {
                Text("Continue as Guest")
                    .fontWeight(.semibold)
                    .foregroundStyle(.nyPink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.nyPink, lineWidth: 1.5)
                    )
            }

            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.nyBody(14))
                    .foregroundStyle(.nyGray)
                Button("Sign Up") {
                    isShowingRegister = true
                }
                .font(.nyBody(14))
                .fontWeight(.semibold)
                .tint(.nyPink)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 40)
    }

    /// Soft white field background with a subtle pink border + shadow so inputs lift
    /// gently off the pink background and feel part of the palette.
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.nyWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.nyLightPink, lineWidth: 1)
            )
            .shadow(color: Color.nyPink.opacity(0.07), radius: 6, y: 3)
    }

    private func handleLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Register View

struct RegisterView: View {
    @ObservedObject var authService: AuthService
    @Binding var isShowingRegister: Bool
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Naturally Yours")
                            .font(.custom("Zapfino", size: 30))
                            .foregroundStyle(.nyPink)

                        Text("Create Account")
                            .font(.nyHeading(24))
                            .foregroundStyle(.nyBlack)

                        Text("Join the Naturally Yours family")
                            .font(.nyBody(14))
                            .foregroundStyle(.nyGray)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 24)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password must contain:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(password.count >= 8 ? .green : .secondary)
                                    .font(.caption)
                                Text("At least 8 characters")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: password.contains(where: { $0.isUppercase }) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(password.contains(where: { $0.isUppercase }) ? .green : .secondary)
                                    .font(.caption)
                                Text("One uppercase letter")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: password.contains(where: { $0.isNumber }) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(password.contains(where: { $0.isNumber }) ? .green : .secondary)
                                    .font(.caption)
                                Text("One number")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: !password.isEmpty && password == confirmPassword ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(!password.isEmpty && password == confirmPassword ? .green : .secondary)
                                    .font(.caption)
                                Text("Passwords match")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        
                        Button {
                            Task {
                                await handleSignup()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal, 30)
                    
                    // Login Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        
                        Button("Log In") {
                            isShowingRegister = false
                        }
                        .fontWeight(.semibold)
                    }
                    .padding(.bottom, 30)
                }
            }
            .alert("Registration Failed", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingRegister = false
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        password.count >= 8 &&
        password.contains(where: { $0.isUppercase }) &&
        password.contains(where: { $0.isNumber }) &&
        password == confirmPassword
    }
    
    private func handleSignup() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signup(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

#Preview("Login") {
    LoginRegisterView()
}
