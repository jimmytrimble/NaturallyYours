import Foundation
import Observation

/// Manages the signed-in user's favorites/wishlist via `/api/favorites`.
///
/// Favorites require authentication on the server; for guests the store simply
/// stays empty and surfaces a sign-in prompt in the UI.
@MainActor
@Observable
final class FavoritesStore {
    private(set) var favorites: [FavoriteDTO] = []
    var isLoading = false
    var errorMessage: String?

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    var isEmpty: Bool { favorites.isEmpty }

    private var favoritedProductIDs: Set<UUID> {
        Set(favorites.map(\.product.id))
    }

    func isFavorite(_ product: CatalogProduct) -> Bool {
        favoritedProductIDs.contains(product.id)
    }

    /// Loads favorites from `GET /api/favorites`. Silently clears on 401 (guest).
    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: FavoritesListResponse = try await client.get("/api/favorites")
            favorites = response.favorites
        } catch let error as APIError where error.isUnauthorized {
            favorites = []
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    /// Adds a favorite via `POST /api/favorites`.
    func add(_ product: CatalogProduct) async throws {
        let body = AddFavoriteRequest(productID: product.id)
        let _: FavoriteDTO = try await client.send("POST", "/api/favorites", body: body)
        await refresh()
    }

    /// Removes a favorite by product via `DELETE /api/favorites/product/:id`.
    func remove(_ product: CatalogProduct) async throws {
        try await client.sendNoContent("DELETE", "/api/favorites/product/\(product.id.uuidString)")
        favorites.removeAll { $0.product.id == product.id }
    }

    /// Toggles favorite state for a product.
    func toggle(_ product: CatalogProduct) async throws {
        if isFavorite(product) {
            try await remove(product)
        } else {
            try await add(product)
        }
    }

    func reset() {
        favorites = []
    }
}
