import SwiftUI

/// Entry point for the staff/admin area. Owns the `AdminService`, restores any
/// existing admin session, and shows either the login screen or the dashboard.
struct AdminGateView: View {
    @State private var adminService = AdminService()
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if adminService.isAuthenticated {
                AdminDashboardView()
            } else {
                AdminLoginView()
            }
        }
        .environment(adminService)
        .task {
            await adminService.restoreSession()
            isCheckingSession = false
        }
    }
}

// MARK: - Login

struct AdminLoginView: View {
    @Environment(AdminService.self) private var adminService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 54))
                        .foregroundStyle(.nyPink)
                    Text("Staff Login")
                        .font(.nyHeading(24))
                        .foregroundStyle(.nyBlack)
                    Text("Sign in with your admin credentials")
                        .font(.nyCaption(13))
                        .foregroundStyle(.nyGray)
                }
                .padding(.top, 40)

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.nyLightGray)
                        .cornerRadius(10)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.nyLightGray)
                        .cornerRadius(10)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.nyCaption(13))
                            .foregroundStyle(.nyError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        login()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.nyPink)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.nyWhite)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await adminService.login(email: email, password: password)
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }
}
