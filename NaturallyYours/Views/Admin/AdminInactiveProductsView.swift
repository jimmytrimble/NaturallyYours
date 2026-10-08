import SwiftUI

/// Lists deactivated products and lets an admin reactivate (reintegrate) them so they
/// reappear in the storefront. Changes are reported back via `onChange` so the parent
/// inventory list stays in sync.
struct AdminInactiveProductsView: View {
    /// `(reactivatedProduct, nil)` when a product is reactivated.
    let onChange: (CatalogProduct?, UUID?) -> Void

    @Environment(AdminService.self) private var adminService

    @State private var products: [CatalogProduct] = []
    @State private var isLoading = false
    @State private var reactivatingIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        List {
            ForEach(products) { product in
                HStack(spacing: 12) {
                    AsyncImage(url: product.primaryImageURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "photo").foregroundStyle(.nyGray.opacity(0.3))
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background(Color.nyLightGray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.name)
                            .font(.nyBody(15)).foregroundStyle(.nyBlack).lineLimit(1)
                        Text("\(product.category) · \(product.formattedPrice)")
                            .font(.nyCaption(12)).foregroundStyle(.nyGray)
                    }

                    Spacer()

                    if reactivatingIDs.contains(product.id) {
                        ProgressView()
                    } else {
                        Button {
                            reactivate(product)
                        } label: {
                            Text("Reactivate")
                                .font(.nyCaption(13)).fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.nySuccess)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.plain)
        .overlay {
            if isLoading && products.isEmpty { ProgressView() }
            else if !isLoading && products.isEmpty {
                ContentUnavailableView("No Inactive Products", systemImage: "archivebox")
            }
        }
        .navigationTitle("Inactive Products")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            products = try await adminService.loadAllProducts(active: false)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    private func reactivate(_ product: CatalogProduct) {
        reactivatingIDs.insert(product.id)
        Task {
            do {
                let updated = try await adminService.setActive(id: product.id, isActive: true)
                products.removeAll { $0.id == updated.id }
                onChange(updated, nil)
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            reactivatingIDs.remove(product.id)
        }
    }
}
