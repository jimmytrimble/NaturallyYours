import SwiftUI

/// Collects contact + shipping details, tokenizes the card, and places the order
/// via `POST /api/checkout`. The server charges Square, creates the order, and
/// clears the cart.
struct CheckoutView: View {
    @Environment(CartStore.self) private var cart
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var orderService = OrderService()
    @State private var showCardEntry = false

    // Contact
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""

    // Shipping
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "US"
    @State private var note = ""

    @State private var isPlacingOrder = false
    @State private var placedOrder: OrderDTO?
    @State private var errorMessage: String?
    @State private var showError = false

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        !line1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !state.trimmingCharacters(in: .whitespaces).isEmpty &&
        !postalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !country.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if let placedOrder {
                    confirmation(for: placedOrder)
                } else {
                    form
                }
            }
            .navigationTitle(placedOrder == nil ? "Checkout" : "Order Confirmed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if placedOrder == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .alert("Checkout Failed", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .onAppear(perform: prefill)
        }
    }

    // MARK: - Form

    private var form: some View {
        Form {
            Section("Contact") {
                TextField("Full name", text: $fullName)
                    .textContentType(.name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                TextField("Phone (optional)", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            Section("Shipping Address") {
                TextField("Address line 1", text: $line1)
                    .textContentType(.streetAddressLine1)
                TextField("Address line 2 (optional)", text: $line2)
                    .textContentType(.streetAddressLine2)
                TextField("City", text: $city)
                    .textContentType(.addressCity)
                TextField("State / Province", text: $state)
                    .textContentType(.addressState)
                TextField("Postal code", text: $postalCode)
                    .textContentType(.postalCode)
                TextField("Country", text: $country)
                    .textContentType(.countryName)
                    .textInputAutocapitalization(.characters)
            }

            Section("Order Note") {
                TextField("Anything we should know? (optional)", text: $note, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(cart.cart.formattedSubtotal).fontWeight(.semibold)
                }
                Text("Shipping and tax are calculated by the server and shown on your confirmation.")
                    .font(.nyCaption(12))
                    .foregroundStyle(.nyGray)
            }

            Section {
                Button {
                    showCardEntry = true
                } label: {
                    HStack {
                        Spacer()
                        if isPlacingOrder {
                            ProgressView().tint(.white)
                        } else {
                            Text("Continue to Payment").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(isValid ? Color.nyPink : Color.nyGray)
                .foregroundStyle(.white)
                .disabled(!isValid || isPlacingOrder || cart.isEmpty)

                Text("Card details are entered securely via Square.")
                    .font(.nyCaption(11))
                    .foregroundStyle(.nyGray)
            }
        }
        .sheet(isPresented: $showCardEntry) {
            SquareCardEntrySheet(displayAmount: cart.cart.formattedSubtotal) { token in
                placeOrder(sourceID: token)
            }
        }
    }

    // MARK: - Confirmation

    private func confirmation(for order: OrderDTO) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.nySuccess)
                    .padding(.top, 40)

                Text("Thank you!")
                    .font(.nyHeading(26))
                    .foregroundStyle(.nyBlack)

                Text("Order \(order.orderNumber)")
                    .font(.nySubheading(16))
                    .foregroundStyle(.nyGray)

                VStack(spacing: 10) {
                    summaryRow("Subtotal", order.formattedSubtotal)
                    summaryRow("Shipping", order.formattedShipping)
                    summaryRow("Tax", order.formattedTax)
                    Divider()
                    summaryRow("Total", order.formattedTotal, bold: true)
                }
                .padding(16)
                .background(Color.nyLightGray)
                .cornerRadius(12)
                .padding(.horizontal, 20)

                Button {
                    dismiss()
                } label: {
                    Text("Continue Shopping")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.nyPink)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(.nyGray)
            Spacer()
            Text(value).fontWeight(bold ? .bold : .regular).foregroundStyle(.nyBlack)
        }
        .font(.nyBody(15))
    }

    // MARK: - Actions

    private func prefill() {
        if let user = authService.currentUser {
            if fullName.isEmpty { fullName = user.name }
            if email.isEmpty { email = user.email }
        }
    }

    private func placeOrder(sourceID: String) {
        isPlacingOrder = true
        Task {
            do {
                let request = CheckoutRequest(
                    sourceID: sourceID,
                    email: email.trimmingCharacters(in: .whitespaces),
                    customerName: fullName.trimmingCharacters(in: .whitespaces),
                    phone: phone.isEmpty ? nil : phone,
                    shipping: ShippingAddressPayload(
                        line1: line1,
                        line2: line2.isEmpty ? nil : line2,
                        city: city,
                        state: state,
                        postalCode: postalCode,
                        country: country
                    ),
                    customerNote: note.isEmpty ? nil : note
                )
                let order = try await orderService.checkout(request)
                cart.reset()
                withAnimation { placedOrder = order }
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isPlacingOrder = false
        }
    }
}
