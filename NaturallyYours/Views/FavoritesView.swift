import SwiftUI

/// Wishlist of favorited products (signed-in users only).
struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites
    @EnvironmentObject private var authService: AuthService

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if !authService.isAuthenticated {
                    signInPrompt
                } else if favorites.isLoading && favorites.isEmpty {
                    ProgressView("Loading favorites…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if favorites.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .background(Color.nyWhite)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CatalogProduct.self) { product in
                ProductDetailView(product: product)
            }
            .task {
                if authService.isAuthenticated { await favorites.refresh() }
            }
            .refreshable {
                if authService.isAuthenticated { await favorites.refresh() }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            NYScreenTitle(title: "Favorites", subtitle: "Your saved products")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(favorites.favorites) { favorite in
                    NavigationLink(value: favorite.product) {
                        ShopProductCard(product: favorite.product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            heartCircle
            Text("No Favorites Yet")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(.nyBlack)
            Text("Tap the heart on any product to save it here.")
                .font(.nyBody(14))
                .foregroundStyle(.nyGray)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var signInPrompt: some View {
        VStack(spacing: 14) {
            heartCircle
            Text("Save Your Favorites")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(.nyBlack)
            Text("Sign in to keep a wishlist of products you love.")
                .font(.nyBody(14))
                .foregroundStyle(.nyGray)
                .multilineTextAlignment(.center)
            Button("Sign In / Create Account") {
                authService.isGuest = false
                authService.isAuthenticated = false
                authService.currentUser = nil
            }
            .buttonStyle(.nyPrimary(fullWidth: false))
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heartCircle: some View {
        Circle()
            .fill(Color.nySoftPink)
            .frame(width: 84, height: 84)
            .overlay {
                Image(systemName: "heart.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.nyPink)
            }
    }
}
