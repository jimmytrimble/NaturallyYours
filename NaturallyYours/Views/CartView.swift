import SwiftUI

/// Shopping cart: line items with quantity controls, subtotal, and checkout.
struct CartView: View {
    @Environment(CartStore.self) private var cart
    @EnvironmentObject private var authService: AuthService

    @State private var showCheckout = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Group {
                if cart.isLoading && cart.isEmpty {
                    ProgressView("Loading cart…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cart.isEmpty {
                    emptyState
                } else {
                    cartContent
                }
            }
            .background(Color.nyWhite)
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .task { await cart.refresh() }
            .refreshable { await cart.refresh() }
            .sheet(isPresented: $showCheckout) {
                CheckoutView()
                    .environment(cart)
                    .environmentObject(authService)
            }
            .alert("Something went wrong", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    // MARK: - Content

    private var cartContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cart.items) { item in
                        CartItemRow(
                            item: item,
                            onUpdate: { newQty in updateQuantity(item: item, quantity: newQty) },
                            onRemove: { removeItem(item) }
                        )
                    }
                }
                .padding(20)
            }

            checkoutBar
        }
    }

    private var checkoutBar: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                    .font(.nyBody(16))
                    .foregroundStyle(.nyGray)
                Spacer()
                Text(cart.cart.formattedSubtotal)
                    .font(.nySubheading(18))
                    .fontWeight(.bold)
                    .foregroundStyle(.nyBlack)
            }

            Text("Shipping & tax calculated at checkout")
                .font(.nyCaption(12))
                .foregroundStyle(.nyGray)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Checkout") {
                showCheckout = true
            }
            .buttonStyle(.nyPrimary)
        }
        .padding(20)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your Cart is Empty", systemImage: "cart")
        } description: {
            Text("Browse the shop and add products you love.")
        }
    }

    // MARK: - Actions

    private func updateQuantity(item: CartItemDTO, quantity: Int) {
        guard let id = item.id else { return }
        Task {
            do { try await cart.updateQuantity(itemID: id, quantity: quantity) }
            catch { present(error) }
        }
    }

    private func removeItem(_ item: CartItemDTO) {
        guard let id = item.id else { return }
        Task {
            do { try await cart.remove(itemID: id) }
            catch { present(error) }
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        showError = true
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let item: CartItemDTO
    let onUpdate: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.product.primaryImageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.nyGray.opacity(0.3))
                }
            }
            .frame(width: 70, height: 70)
            .background(Color.nyLightGray)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.product.name)
                    .font(.nyBody(15))
                    .fontWeight(.semibold)
                    .foregroundStyle(.nyBlack)
                    .lineLimit(2)

                Text(item.formattedLineTotal)
                    .font(.nySubheading(15))
                    .foregroundStyle(.nyBlack)

                Stepper(value: Binding(
                    get: { item.quantity },
                    set: { onUpdate($0) }
                ), in: 1...99) {
                    Text("Qty \(item.quantity)")
                        .font(.nyCaption(13))
                        .foregroundStyle(.nyGray)
                }
            }

            Spacer(minLength: 0)

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.nyError)
            }
        }
        .padding(12)
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }
}
