import SwiftUI
import UniformTypeIdentifiers

/// Tabbed admin dashboard: inventory, orders, and the support inbox.
struct AdminDashboardView: View {
    var body: some View {
        TabView {
            NavigationStack { AdminInventoryView() }
                .tabItem { Label("Inventory", systemImage: "shippingbox") }

            NavigationStack { AdminOrdersView() }
                .tabItem { Label("Orders", systemImage: "list.bullet.rectangle") }

            NavigationStack { AdminInboxView() }
                .tabItem { Label("Inbox", systemImage: "tray.full") }
        }
        .tint(.nyPink)
    }
}

// MARK: - Shared admin toolbar (exit + logout)

private struct AdminToolbarModifier: ViewModifier {
    @Environment(AdminService.self) private var adminService
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let admin = adminService.admin {
                        Text("\(admin.name) · \(admin.role.displayName)")
                    }
                    Button(role: .destructive) {
                        Task { await adminService.logout() }
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    Button {
                        dismiss()
                    } label: {
                        Label("Exit Admin", systemImage: "xmark")
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(.nyPink)
                }
            }
        }
    }
}

extension View {
    func adminToolbar() -> some View { modifier(AdminToolbarModifier()) }
}

// MARK: - Inventory

struct AdminInventoryView: View {
    @Environment(AdminService.self) private var adminService

    @State private var allProducts: [CatalogProduct] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showNewProduct = false
    @State private var showImporter = false
    @State private var exportDocument: CSVDocument?
    @State private var showExporter = false
    @State private var banner: String?
    @State private var errorMessage: String?
    @State private var showError = false

    private var activeProducts: [CatalogProduct] {
        let base = allProducts.filter { $0.isActive }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter { $0.name.lowercased().contains(q) || ($0.sku?.lowercased().contains(q) ?? false) }
    }

    private var inactiveCount: Int {
        allProducts.filter { !$0.isActive }.count
    }

    var body: some View {
        List {
            if let banner {
                Text(banner)
                    .font(.nyCaption(13))
                    .foregroundStyle(.nySuccess)
            }

            if inactiveCount > 0 {
                NavigationLink {
                    AdminInactiveProductsView(onChange: handleChange)
                } label: {
                    Label("Inactive Products (\(inactiveCount))", systemImage: "archivebox")
                        .foregroundStyle(.nyGray)
                }
            }

            ForEach(activeProducts) { product in
                NavigationLink {
                    AdminProductEditView(mode: .edit(product), onChange: handleChange)
                } label: {
                    AdminProductRow(product: product)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search by name or SKU")
        .overlay {
            if isLoading && allProducts.isEmpty { ProgressView() }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .adminToolbar()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showNewProduct = true
                    } label: { Label("New Product", systemImage: "plus") }

                    if adminService.canManageCatalog {
                        Button {
                            showImporter = true
                        } label: { Label("Import CSV", systemImage: "square.and.arrow.down") }

                        Button {
                            exportCSV()
                        } label: { Label("Export CSV", systemImage: "square.and.arrow.up") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(.nyPink)
                }
            }
        }
        .sheet(isPresented: $showNewProduct) {
            NavigationStack {
                AdminProductEditView(mode: .create, onChange: handleChange)
            }
            .environment(adminService)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            handleImport(result)
        }
        .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .commaSeparatedText, defaultFilename: "products-export") { _ in }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        do {
            // Admin list includes inactive products (the public catalog hides them).
            allProducts = try await adminService.loadAllProducts()
        } catch {
            present(error)
        }
        isLoading = false
    }

    private func handleChange(_ updated: CatalogProduct?, deletedID: UUID?) {
        if let deletedID {
            allProducts.removeAll { $0.id == deletedID }
        } else if let updated {
            if let idx = allProducts.firstIndex(where: { $0.id == updated.id }) {
                allProducts[idx] = updated
            } else {
                allProducts.insert(updated, at: 0)
            }
        }
    }

    private func exportCSV() {
        Task {
            do {
                let data = try await adminService.exportCSV()
                exportDocument = CSVDocument(text: String(decoding: data, as: UTF8.self))
                showExporter = true
            } catch { present(error) }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        Task {
            do {
                let url = try result.get()
                let needsStop = url.startAccessingSecurityScopedResource()
                defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                let csv = try String(contentsOf: url, encoding: .utf8)
                let importResult = try await adminService.importCSV(csv)
                banner = "Imported: \(importResult.created) created, \(importResult.updated) updated."
                await load()
            } catch {
                present(error)
            }
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        showError = true
    }
}

struct AdminProductRow: View {
    let product: CatalogProduct

    var body: some View {
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
                    .font(.nyBody(15))
                    .foregroundStyle(.nyBlack)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(product.formattedPrice).foregroundStyle(.nyBlack)
                    Text("Stock \(product.stockQuantity)")
                        .foregroundStyle(product.inStock ? .nyGray : .nyError)
                }
                .font(.nyCaption(12))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
