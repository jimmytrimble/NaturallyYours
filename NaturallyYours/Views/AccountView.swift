import SwiftUI

/// Account hub: profile, order history, support, and sign out.
struct AccountView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(CartStore.self) private var cart
    @Environment(FavoritesStore.self) private var favorites

    @State private var orderService = OrderService()
    @State private var showAdmin = false
    @State private var showContact = false

    var body: some View {
        NavigationStack {
            List {
                profileSection

                if authService.isAuthenticated {
                    ordersSection
                }

                supportSection

                accountActionsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: OrderDTO.self) { order in
                OrderDetailView(order: order)
            }
            .task {
                if authService.isAuthenticated { await orderService.loadMyOrders() }
            }
            .fullScreenCover(isPresented: $showAdmin) {
                AdminGateView()
            }
            .sheet(isPresented: $showContact) {
                ContactView()
                    .environmentObject(authService)
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section {
            if let user = authService.currentUser {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.nyLightPink)
                        .frame(width: 54, height: 54)
                        .overlay {
                            Text(initials(for: user.name))
                                .font(.nySubheading(18))
                                .foregroundStyle(.nyPink)
                        }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.name)
                            .font(.nySubheading(17))
                            .foregroundStyle(.nyBlack)
                        Text(user.email)
                            .font(.nyCaption(13))
                            .foregroundStyle(.nyGray)
                    }
                }
                .padding(.vertical, 6)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("You're browsing as a guest")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(.nyBlack)
                    Text("Sign in to save favorites and track orders.")
                        .font(.nyCaption(13))
                        .foregroundStyle(.nyGray)
                    Button("Sign In / Create Account") {
                        signOutToLogin()
                    }
                    .buttonStyle(.nyPrimary)
                    .padding(.top, 4)
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var ordersSection: some View {
        Section("Order History") {
            if orderService.isLoading && orderService.orders.isEmpty {
                ProgressView()
            } else if orderService.orders.isEmpty {
                Text("No orders yet.")
                    .font(.nyBody(14))
                    .foregroundStyle(.nyGray)
            } else {
                ForEach(orderService.orders) { order in
                    NavigationLink(value: order) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(order.orderNumber)
                                    .font(.nyBody(15))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.nyBlack)
                                Spacer()
                                Text(order.formattedTotal)
                                    .font(.nyBody(15))
                                    .foregroundStyle(.nyBlack)
                            }
                            Text(order.status.displayName)
                                .font(.nyCaption(12))
                                .foregroundStyle(.nyGray)
                        }
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Button {
                showContact = true
            } label: {
                Label("Contact Us", systemImage: "envelope")
                    .foregroundStyle(.nyBlack)
            }
            NavigationLink {
                AboutView()
            } label: {
                Label("About Naturally Yours", systemImage: "info.circle")
            }
            Button {
                showAdmin = true
            } label: {
                Label("Staff Login", systemImage: "lock.shield")
                    .foregroundStyle(.nyBlack)
            }
        }
    }

    private var accountActionsSection: some View {
        Section {
            Button(role: .destructive) {
                if authService.isAuthenticated {
                    Task { try? await authService.logout(); afterSignOut() }
                } else {
                    signOutToLogin()
                }
            } label: {
                Label(authService.isAuthenticated ? "Log Out" : "Exit Guest Mode",
                      systemImage: "rectangle.portrait.and.arrow.right")
            }
        } footer: {
            Text("\(AppConfiguration.appName) v\(AppConfiguration.appVersion)")
                .font(.nyCaption(11))
                .foregroundStyle(.nyGray)
        }
    }

    // MARK: - Helpers

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private func signOutToLogin() {
        // Guests have no session to clear; just flip auth state back to login.
        authService.isGuest = false
        authService.isAuthenticated = false
        authService.currentUser = nil
        afterSignOut()
    }

    private func afterSignOut() {
        cart.reset()
        favorites.reset()
    }
}

// MARK: - Order Detail

struct OrderDetailView: View {
    let order: OrderDTO

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(order.status.displayName).foregroundStyle(.nyGray)
                }
                if let created = order.createdAt {
                    HStack {
                        Text("Placed")
                        Spacer()
                        Text(created, style: .date).foregroundStyle(.nyGray)
                    }
                }
            }

            Section("Items") {
                ForEach(order.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(.nyBody(15))
                                .foregroundStyle(.nyBlack)
                            Text("Qty \(item.quantity) · \(item.formattedUnitPrice)")
                                .font(.nyCaption(12))
                                .foregroundStyle(.nyGray)
                        }
                        Spacer()
                        Text(item.formattedLineTotal)
                            .font(.nyBody(15))
                            .foregroundStyle(.nyBlack)
                    }
                }
            }

            Section("Summary") {
                summaryRow("Subtotal", order.formattedSubtotal)
                summaryRow("Shipping", order.formattedShipping)
                summaryRow("Tax", order.formattedTax)
                summaryRow("Total", order.formattedTotal, bold: true)
            }

            Section("Shipping To") {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.customerName)
                    Text(order.shippingLine1)
                    if let line2 = order.shippingLine2, !line2.isEmpty { Text(line2) }
                    Text("\(order.shippingCity), \(order.shippingState) \(order.shippingPostalCode)")
                    Text(order.shippingCountry)
                }
                .font(.nyBody(14))
                .foregroundStyle(.nyBlack)
            }
        }
        .navigationTitle(order.orderNumber)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).fontWeight(bold ? .bold : .regular)
        }
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Naturally Yours Beauty Supply")
                    .font(.nyHeading(22))
                    .foregroundStyle(.nyBlack)
                Text("""
                We're dedicated to providing premium natural hair and skincare \
                products. From curated bundles to trusted brands, Naturally Yours \
                helps you look and feel your best.
                """)
                .font(.nyBody(15))
                .foregroundStyle(.nyGray)
            }
            .padding(20)
        }
        .background(Color.nyWhite)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension OrderDTO: Hashable {
    static func == (lhs: OrderDTO, rhs: OrderDTO) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
