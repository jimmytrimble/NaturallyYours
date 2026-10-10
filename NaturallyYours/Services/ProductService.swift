import Foundation
import Observation

/// Loads the public product catalog from the server.
@MainActor
@Observable
final class ProductService {
    var products: [CatalogProduct] = []
    var featuredProducts: [CatalogProduct] = []
    var isLoading = false
    var errorMessage: String?

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    /// Distinct categories present in the loaded catalog, in a stable, store-friendly order.
    var categories: [String] {
        let preferredOrder = ["Bundles", "Skincare", "Haircare", "Treatments", "Men"]
        let present = Set(products.map(\.category))
        let ordered = preferredOrder.filter(present.contains)
        let extras = present.subtracting(ordered).sorted()
        return ordered + extras
    }

    func products(in category: String) -> [CatalogProduct] {
        products.filter { $0.category == category }
    }

    /// Loads the full active catalog (one large page) from `GET /api/products`.
    func loadProducts(force: Bool = false) async {
        if !force && !products.isEmpty { return }

        isLoading = true
        errorMessage = nil
        do {
            let page: Page<CatalogProduct> = try await client.get(
                "/api/products",
                query: [URLQueryItem(name: "per", value: "200")]
            )
            products = page.items
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    /// Loads the admin-curated featured best-sellers from `GET /api/products/featured`.
    func loadFeatured(force: Bool = false) async {
        if !force && !featuredProducts.isEmpty { return }
        featuredProducts = (try? await client.get("/api/products/featured")) ?? []
    }

    /// Fetches a single product by id from `GET /api/products/:id`.
    func product(id: UUID) async throws -> CatalogProduct {
        try await client.get("/api/products/\(id.uuidString)")
    }

    /// Searches products via `GET /api/products/search?q=`.
    func search(_ query: String) async throws -> [CatalogProduct] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return try await client.get(
            "/api/products/search",
            query: [URLQueryItem(name: "q", value: query)]
        )
    }
}
