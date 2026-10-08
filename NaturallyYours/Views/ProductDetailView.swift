import SwiftUI

/// Full product page: image carousel, price, description, quantity, add-to-cart,
/// and favorite toggle. Reads shared stores from the environment.
struct ProductDetailView: View {
    let product: CatalogProduct

    @Environment(CartStore.self) private var cart
    @Environment(FavoritesStore.self) private var favorites
    @EnvironmentObject private var authService: AuthService

    @State private var quantity = 1
    @State private var isAddingToCart = false
    @State private var showAddedConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var maxQuantity: Int {
        max(1, min(product.stockQuantity, 99))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                imageCarousel

                VStack(alignment: .leading, spacing: 12) {
                    Text(product.category.uppercased())
                        .font(.nyCaption(12))
                        .foregroundStyle(.nyGray)
                        .tracking(1)

                    Text(product.name)
                        .font(.nyHeading(24))
                        .foregroundStyle(.nyBlack)

                    priceRow

                    stockRow

                    Divider().padding(.vertical, 4)

                    Text("Description")
                        .font(.nySubheading(16))
                        .foregroundStyle(.nyBlack)

                    Text(cleanedDescription)
                        .font(.nyBody(15))
                        .foregroundStyle(.nyGray)
                        .fixedSize(horizontal: false, vertical: true)

                    if !product.tags.isEmpty {
                        tagsRow
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .background(Color.nyWhite)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            addToCartBar
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: favorites.isFavorite(product) ? "heart.fill" : "heart")
                        .foregroundStyle(.nyPink)
                }
            }
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    // MARK: - Image carousel

    private var imageCarousel: some View {
        Group {
            let urls = product.resolvedImageURLs
            if urls.isEmpty {
                placeholder
            } else {
                TabView {
                    ForEach(urls, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                            case .failure:
                                placeholder
                            case .empty:
                                ProgressView()
                            @unknown default:
                                placeholder
                            }
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 320)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.nyLightGray)
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.system(size: 50))
            .foregroundStyle(.nyGray.opacity(0.3))
            .frame(height: 320)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Info rows

    private var priceRow: some View {
        HStack(spacing: 10) {
            Text(product.formattedPrice)
                .font(.nyHeading(26))
                .foregroundStyle(.nyBlack)

            if product.onSale {
                Text(product.formattedOriginalPrice)
                    .font(.nyBody(17))
                    .foregroundStyle(.nyGray)
                    .strikethrough()

                Text("SALE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.nyPink)
                    .cornerRadius(4)
            }
        }
    }

    private var stockRow: some View {
        HStack(spacing: 6) {
            Image(systemName: product.inStock ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(product.inStock ? .nySuccess : .nyError)
            Text(product.inStock ? "In stock" : "Sold out")
                .font(.nyBody(14))
                .foregroundStyle(.nyGray)
        }
    }

    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(product.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.nyCaption(12))
                        .foregroundStyle(.nyGray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.nyLightGray)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Add to cart bar

    private var addToCartBar: some View {
        HStack(spacing: 12) {
            if product.inStock {
                Stepper(value: $quantity, in: 1...maxQuantity) {
                    Text("Qty \(quantity)")
                        .font(.nyBody(15))
                        .foregroundStyle(.nyBlack)
                }
                .frame(width: 140)
            }

            Button {
                addToCart()
            } label: {
                Group {
                    if isAddingToCart {
                        ProgressView().tint(.white)
                    } else {
                        Text(product.inStock ? "Add to Cart" : "Sold Out")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(product.inStock ? Color.nyPink : Color.nyGray)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .disabled(!product.inStock || isAddingToCart)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            if showAddedConfirmation {
                Text("Added to cart")
                    .font(.nyCaption(13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.nySuccess)
                    .clipShape(Capsule())
                    .padding(.top, -34)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Actions

    private var cleanedDescription: String {
        // Catalog descriptions can contain simple HTML from the source feed; strip tags
        // for a clean reading experience.
        let withoutTags = product.description.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        return withoutTags
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addToCart() {
        isAddingToCart = true
        Task {
            do {
                try await cart.add(product: product, quantity: quantity)
                withAnimation { showAddedConfirmation = true }
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation { showAddedConfirmation = false }
            } catch {
                present(error)
            }
            isAddingToCart = false
        }
    }

    private func toggleFavorite() {
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to save favorites."
            showError = true
            return
        }
        Task {
            do {
                try await favorites.toggle(product)
            } catch {
                present(error)
            }
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        showError = true
    }
}
