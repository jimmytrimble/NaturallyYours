import SwiftUI

/// Admin screen to curate the Home "Featured Best Sellers" rail: see what's featured,
/// remove items, and add any active product.
struct AdminFeaturedView: View {
    @Environment(AdminService.self) private var adminService
    @Environment(\.dismiss) private var dismiss

    @State private var products: [CatalogProduct] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var busyIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showError = false

    private var featured: [CatalogProduct] {
        products.filter { $0.featured }.sorted { $0.name < $1.name }
    }

    private var addable: [CatalogProduct] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return products
            .filter { $0.isActive && !$0.featured }
            .filter { q.isEmpty || $0.name.lowercased().contains(q) || ($0.sku?.lowercased().contains(q) ?? false) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Featured (\(featured.count))") {
                    if featured.isEmpty {
                        Text("No featured products yet. Add some from the list below.")
                            .font(.nyBody(14))
                            .foregroundStyle(.nyGray)
                    } else {
                        ForEach(featured) { product in
                            productRow(product, isFeatured: true)
                        }
                    }
                }

                Section("Add a Product") {
                    if addable.isEmpty {
                        Text(searchText.isEmpty ? "All active products are featured." : "No matches.")
                            .font(.nyBody(14))
                            .foregroundStyle(.nyGray)
                    } else {
                        ForEach(addable) { product in
                            productRow(product, isFeatured: false)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search products to add")
            .overlay {
                if isLoading && products.isEmpty { ProgressView() }
            }
            .navigationTitle("Featured Best Sellers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Something went wrong", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .task { await load() }
        }
    }

    private func productRow(_ product: CatalogProduct, isFeatured: Bool) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: product.primaryImageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "photo").foregroundStyle(.nyGray.opacity(0.3))
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.nyLightGray)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.nyBody(15)).foregroundStyle(.nyBlack).lineLimit(1)
                Text(product.formattedPrice)
                    .font(.nyCaption(12)).foregroundStyle(.nyGray)
            }

            Spacer()

            if busyIDs.contains(product.id) {
                ProgressView()
            } else if isFeatured {
                Button {
                    toggle(product, featured: false)
                } label: {
                    Image(systemName: "star.slash")
                        .foregroundStyle(.nyError)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    toggle(product, featured: true)
                } label: {
                    Image(systemName: "star")
                        .foregroundStyle(.nyPink)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    private func load() async {
        isLoading = true
        do {
            products = try await adminService.loadAllProducts()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    private func toggle(_ product: CatalogProduct, featured: Bool) {
        busyIDs.insert(product.id)
        Task {
            do {
                let updated = try await adminService.setFeatured(id: product.id, featured: featured)
                if let idx = products.firstIndex(where: { $0.id == updated.id }) {
                    products[idx] = updated
                }
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            busyIDs.remove(product.id)
        }
    }
}
