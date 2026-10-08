import Foundation
import Observation

/// Handles checkout and customer order history via `/api/checkout` and `/api/orders`.
@MainActor
@Observable
final class OrderService {
    var orders: [OrderDTO] = []
    var isLoading = false
    var errorMessage: String?

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    /// Loads the signed-in user's order history from `GET /api/orders`.
    /// Clears silently for guests (401).
    func loadMyOrders() async {
        isLoading = true
        errorMessage = nil
        do {
            orders = try await client.get("/api/orders")
        } catch let error as APIError where error.isUnauthorized {
            orders = []
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    /// Fetches a single order via `GET /api/orders/:id`.
    func order(id: UUID) async throws -> OrderDTO {
        try await client.get("/api/orders/\(id.uuidString)")
    }

    /// Places an order via `POST /api/checkout`. The server charges Square using the
    /// supplied payment `sourceID`, creates the order, decrements stock, and clears
    /// the cart. Returns the created order.
    func checkout(_ request: CheckoutRequest) async throws -> OrderDTO {
        try await client.send("POST", "/api/checkout", body: request)
    }
}
