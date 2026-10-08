import Foundation
import Observation

/// Holds the current cart (guest or authenticated) and talks to `/api/cart`.
///
/// The server tracks a guest cart via the session cookie, so the same store works
/// before and after login; `APIClient` carries the cookie automatically.
@MainActor
@Observable
final class CartStore {
    private(set) var cart: CartDTO = .empty
    var isLoading = false
    var errorMessage: String?

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    var itemCount: Int { cart.itemCount }
    var items: [CartItemDTO] { cart.items }
    var isEmpty: Bool { cart.items.isEmpty }

    /// Loads the current cart from `GET /api/cart`.
    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            cart = try await client.get("/api/cart")
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    /// Adds a product to the cart via `POST /api/cart/items`. Returns the refreshed cart.
    @discardableResult
    func add(product: CatalogProduct, quantity: Int = 1) async throws -> CartDTO {
        let body = AddToCartRequest(productID: product.id, quantity: quantity)
        cart = try await client.send("POST", "/api/cart/items", body: body)
        return cart
    }

    /// Updates a line item's quantity via `PATCH /api/cart/items/:id` (0 removes it).
    func updateQuantity(itemID: UUID, quantity: Int) async throws {
        let body = UpdateCartItemRequest(quantity: quantity)
        cart = try await client.send("PATCH", "/api/cart/items/\(itemID.uuidString)", body: body)
    }

    /// Removes a line item via `DELETE /api/cart/items/:id`.
    func remove(itemID: UUID) async throws {
        try await client.sendNoContent("DELETE", "/api/cart/items/\(itemID.uuidString)")
        await refresh()
    }

    /// Clears all items via `DELETE /api/cart/clear`.
    func clear() async throws {
        try await client.sendNoContent("DELETE", "/api/cart/clear")
        cart = .empty
    }

    /// Resets local state after checkout/logout without a network call.
    func reset() {
        cart = .empty
    }
}
