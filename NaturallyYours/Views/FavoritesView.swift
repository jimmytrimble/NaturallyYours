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
        ContentUnavailableView {
            Label("No Favorites Yet", systemImage: "heart")
        } description: {
            Text("Tap the heart on any product to save it here.")
        }
    }

    private var signInPrompt: some View {
        ContentUnavailableView {
            Label("Sign In to View Favorites", systemImage: "heart")
        } description: {
            Text("Favorites are saved to your account.")
        }
    }
}
