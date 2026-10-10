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

            NavigationStack { AdminVendingView() }
                .tabItem { Label("Vending", systemImage: "cabinet") }

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
    @State private var showFeatured = false
    @State private var showImporter = false
    @State private var exportDocument: CSVDocument?
    @State private var showExporter = false
    @State private var banner: String?
    @State private var stats: AdminStats?
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

    /// Persisted inventory layout preference (list vs. grid).
    @AppStorage("adminInventoryUseGrid") private var useGrid = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if useGrid { gridContent } else { listContent }
        }
        .searchable(text: $searchText, prompt: "Search by name or SKU")
        .overlay {
            if isLoading && allProducts.isEmpty { ProgressView() }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .adminToolbar()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation { useGrid.toggle() }
                } label: {
                    Image(systemName: useGrid ? "list.bullet" : "square.grid.2x2")
                        .foregroundStyle(.nyPink)
                }
                .accessibilityLabel(useGrid ? "View as list" : "View as grid")
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showNewProduct = true
                    } label: { Label("New Product", systemImage: "plus") }

                    Button {
                        showFeatured = true
                    } label: { Label("Manage Featured", systemImage: "star") }

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
        .sheet(isPresented: $showFeatured, onDismiss: { Task { await load() } }) {
            AdminFeaturedView()
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

    // MARK: - Layouts

    private var listContent: some View {
        List {
            if let stats {
                statsStrip(stats)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            if let banner {
                Text(banner).font(.nyCaption(13)).foregroundStyle(.nySuccess)
            }
            if inactiveCount > 0 {
                inactiveLink
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
    }

    private var gridContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let stats {
                    statsStrip(stats)
                }
                if let banner {
                    Text(banner).font(.nyCaption(13)).foregroundStyle(.nySuccess)
                }
                if inactiveCount > 0 {
                    inactiveLink
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.nyLightGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(activeProducts) { product in
                        NavigationLink {
                            AdminProductEditView(mode: .edit(product), onChange: handleChange)
                        } label: {
                            AdminProductGridCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
    }

    private func statsStrip(_ stats: AdminStats) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statPill("Products", stats.totalProducts)
                statPill("Active", stats.activeProducts)
                statPill("Orders", stats.orders)
                statPill("Messages", stats.openConversations)
                statPill("Customers", stats.users)
            }
        }
    }

    private func statPill(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(.nyBlack)
            Text(label)
                .font(.nyCaption(11))
                .foregroundStyle(.nyGray)
        }
        .frame(minWidth: 68)
        .padding(.vertical, 10)
        .background(Color.nyLightGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var inactiveLink: some View {
        NavigationLink {
            AdminInactiveProductsView(onChange: handleChange)
        } label: {
            Label("Inactive Products (\(inactiveCount))", systemImage: "archivebox")
                .foregroundStyle(.nyGray)
        }
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
        stats = try? await adminService.loadStats()
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

struct AdminProductGridCard: View {
    let product: CatalogProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.nyLightGray)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    AsyncImage(url: product.primaryImageURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(.nyGray.opacity(0.3))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(product.name)
                .font(.nyBody(14))
                .fontWeight(.semibold)
                .foregroundStyle(.nyBlack)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 6) {
                Text(product.formattedPrice).foregroundStyle(.nyBlack)
                Spacer()
                Text("Stock \(product.stockQuantity)")
                    .foregroundStyle(product.inStock ? .nyGray : .nyError)
            }
            .font(.nyCaption(12))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }
}
