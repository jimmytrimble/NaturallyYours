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
        NavigationStack {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green.gradient)
                    
                    Text("Naturally Yours")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Natural Beauty Products")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button {
                        Task {
                            await handleLogin()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                .padding(.horizontal, 30)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.secondary.opacity(0.3))
                    
                    Text("or")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.secondary.opacity(0.3))
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                
                // Guest Button
                Button {
                    authService.continueAsGuest()
                } label: {
                    Text("Continue as Guest")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Register Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    
                    Button("Sign Up") {
                        isShowingRegister = true
                    }
                    .fontWeight(.semibold)
                }
                .padding(.bottom, 30)
            }
            .alert("Login Failed", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
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
                    VStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green.gradient)
                        
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Join Naturally Yours today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    
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
