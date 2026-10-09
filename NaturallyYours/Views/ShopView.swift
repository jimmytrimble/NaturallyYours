import SwiftUI

/// Browse the catalog: category chips, search, and a product grid. Reads the shared
/// `ProductService` from the environment (injected at the app root).
struct ShopView: View {
    @Environment(ProductService.self) private var productService

    /// Optional category to preselect when pushed from Home.
    var initialCategory: String? = nil

    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var searchResults: [CatalogProduct] = []
    @State private var isSearching = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var displayedProducts: [CatalogProduct] {
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return searchResults
        }
        if let selectedCategory {
            return productService.products(in: selectedCategory)
        }
        return productService.products
    }

    var body: some View {
        Group {
            if productService.isLoading && productService.products.isEmpty {
                ProgressView("Loading products…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = productService.errorMessage, productService.products.isEmpty {
                errorState(errorMessage)
            } else if productService.products.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Color.nyWhite)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search products")
        .onChange(of: searchText) { _, _ in
            Task { await runSearch() }
        }
        .task {
            selectedCategory = initialCategory
            await productService.loadProducts()
        }
        .refreshable {
            await productService.loadProducts(force: true)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            NYScreenTitle(title: "Shop", subtitle: "Find your next favorite")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                categoryChips
            }

            if displayedProducts.isEmpty {
                Text(searchText.isEmpty ? "No products in this category." : "No results for “\(searchText)”.")
                    .font(.nyBody(15))
                    .foregroundStyle(.nyGray)
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(displayedProducts) { product in
                        NavigationLink(value: product) {
                            ShopProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .navigationDestination(for: CatalogProduct.self) { product in
            ProductDetailView(product: product)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(productService.categories, id: \.self) { category in
                    chip(title: category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.nyBody(14))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .nyBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        Capsule().fill(LinearGradient.nyBrand)
                    } else {
                        Capsule().fill(Color.nyLightGray)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search

    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        searchResults = (try? await productService.search(query)) ?? []
    }

    // MARK: - Empty / Error states

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Products Yet", systemImage: "bag")
        } description: {
            Text("Products will appear here once the server catalog is seeded.")
        } actions: {
            Button("Reload") {
                Task { await productService.loadProducts(force: true) }
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
                Task { await productService.loadProducts(force: true) }
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
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.nyLightGray)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        AsyncImage(url: product.primaryImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if product.onSale {
                    badge("SALE", gradient: true)
                } else if !product.inStock {
                    badge("SOLD OUT", gradient: false)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(product.category.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.nyGray)

                Text(product.name)
                    .font(.nyBody(14))
                    .foregroundStyle(.nyBlack)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 36, alignment: .top)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(product.formattedPrice)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(product.onSale ? .nyPink : .nyBlack)

                    if product.onSale {
                        Text(product.formattedOriginalPrice)
                            .font(.nyCaption(13))
                            .foregroundStyle(.nyGray)
                            .strikethrough()
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(10)
        .background(Color.nyWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .nyCardShadow()
    }

    private var placeholderIcon: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(.nyGray.opacity(0.3))
    }

    private func badge(_ text: String, gradient: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                if gradient {
                    Capsule().fill(LinearGradient.nyBrand)
                } else {
                    Capsule().fill(Color.nyBlack.opacity(0.75))
                }
            }
            .padding(10)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShopView()
    }
    .environment(ProductService())
}
