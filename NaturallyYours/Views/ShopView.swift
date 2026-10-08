import SwiftUI
import Observation

// MARK: - Catalog Product Model

/// A product as returned by the server's `GET /api/products` endpoint.
///
/// This maps the server `ProductDTO`. The Vapor JSON encoder emits camelCase
/// keys (no snake_case conversion is configured server-side), so the property
/// names match the JSON keys directly. Fields we don't need (createdAt,
/// updatedAt, weight, tags) are simply omitted — extra JSON keys are ignored.
struct CatalogProduct: Identifiable, Decodable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let salePrice: Double?
    let effectivePrice: Double
    let category: String
    let stockQuantity: Int
    let inStock: Bool
    let onSale: Bool
    let imageURLs: [String]
    let sku: String?
    let highlights: [String]

    /// First image URL, if any, for the product thumbnail.
    var primaryImageURL: URL? {
        imageURLs.first.flatMap(URL.init(string:))
    }

    var formattedPrice: String {
        String(format: "$%.2f", effectivePrice)
    }

    var formattedOriginalPrice: String {
        String(format: "$%.2f", price)
    }
}

/// The paginated envelope Vapor's `.paginate(for:)` returns:
/// `{ "items": [...], "metadata": { "page": 1, "per": 200, "total": 42 } }`.
private struct ProductPage: Decodable {
    let items: [CatalogProduct]
}

// MARK: - Shop View Model

@MainActor
@Observable
final class ShopViewModel {
    var products: [CatalogProduct] = []
    var isLoading = false
    var errorMessage: String?

    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfiguration.requestTimeout
        return URLSession(configuration: config)
    }

    /// Fetch the active product catalog from the server.
    /// Requests a large page size so the whole catalog comes back in one call.
    func loadProducts() async {
        guard let url = URL(string: "\(AppConfiguration.apiBaseURL)/api/products?per=200") else {
            errorMessage = "Invalid server URL"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, response) = try await session.data(from: url)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard http.statusCode == 200 else {
                throw NSError(
                    domain: "Shop",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Server returned status \(http.statusCode)"]
                )
            }

            let page = try JSONDecoder().decode(ProductPage.self, from: data)
            products = page.items
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Shop View

struct ShopView: View {
    @State private var viewModel = ShopViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView("Loading products…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.products.isEmpty {
                errorState(errorMessage)
            } else if viewModel.products.isEmpty {
                emptyState
            } else {
                productGrid
            }
        }
        .background(Color.nyWhite)
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.products.isEmpty {
                await viewModel.loadProducts()
            }
        }
        .refreshable {
            await viewModel.loadProducts()
        }
    }

    // MARK: - Product Grid

    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.products) { product in
                    ShopProductCard(product: product)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Empty / Error States

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Products Yet", systemImage: "bag")
        } description: {
            Text("Products added in Baserow will appear here once the server syncs.")
        } actions: {
            Button("Reload") {
                Task { await viewModel.loadProducts() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.nyPink)
        }
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't Load Products", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.loadProducts() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.nyPink)
        }
    }
}

// MARK: - Shop Product Card

struct ShopProductCard: View {
    let product: CatalogProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product image
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nyLightGray)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        AsyncImage(url: product.primaryImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholderIcon
                            case .empty:
                                if product.primaryImageURL == nil {
                                    placeholderIcon
                                } else {
                                    ProgressView()
                                }
                            @unknown default:
                                placeholderIcon
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if product.onSale {
                    badge("SALE")
                } else if !product.inStock {
                    badge("SOLD OUT")
                }
            }

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.category)
                    .font(.nyCaption(12))
                    .foregroundStyle(.nyGray)

                Text(product.name)
                    .font(.nyBody(15))
                    .foregroundStyle(.nyBlack)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(product.formattedPrice)
                        .font(.nySubheading(17))
                        .foregroundStyle(.nyBlack)
                        .fontWeight(.bold)

                    if product.onSale {
                        Text(product.formattedOriginalPrice)
                            .font(.nyCaption(13))
                            .foregroundStyle(.nyGray)
                            .strikethrough()
                    }
                }
            }
        }
        .padding(12)
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }

    private var placeholderIcon: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(.nyGray.opacity(0.3))
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.nyPink)
            .cornerRadius(4)
            .padding(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShopView()
    }
}
