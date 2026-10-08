import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Create or edit a product: core fields, price/stock, active state, image upload,
/// and delete. Changes are reported back to the inventory list via `onChange`.
struct AdminProductEditView: View {
    enum Mode {
        case create
        case edit(CatalogProduct)
    }

    let mode: Mode
    /// `(updatedOrCreated, deletedID)` — exactly one is non-nil per callback.
    let onChange: (CatalogProduct?, UUID?) -> Void

    @Environment(AdminService.self) private var adminService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var category = ""
    @State private var priceText = ""
    @State private var salePriceText = ""
    @State private var stockText = ""
    @State private var sku = ""
    @State private var tagsText = ""
    @State private var isActive = true
    @State private var imageURLs: [String] = []

    @State private var editingProductID: UUID?
    @State private var photoItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { editingProductID != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !category.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(priceText) != nil &&
        Int(stockText) != nil
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
                TextField("Category", text: $category)
                TextField("SKU (optional)", text: $sku)
                TextField("Tags (comma separated)", text: $tagsText)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Pricing & Stock") {
                priceField("Price", text: $priceText)
                priceField("Sale price (optional)", text: $salePriceText)
                TextField("Stock quantity", text: $stockText)
                    .keyboardType(.numberPad)
            }

            if isEditing {
                Section("Availability") {
                    Toggle("Active (visible in store)", isOn: $isActive)
                }
                imagesSection
            }

            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        if isSaving { ProgressView().tint(.white) }
                        else { Text(isEditing ? "Save Changes" : "Create Product").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .listRowBackground(isValid ? Color.nyPink : Color.nyGray)
                .foregroundStyle(.white)
                .disabled(!isValid || isSaving)
            }

            if isEditing {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Product", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Product" : "New Product")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: populate)
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .confirmationDialog("Delete this product?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Images

    private var imagesSection: some View {
        Section("Images") {
            if !imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(imageURLs, id: \.self) { raw in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: APIClient.shared.imageURL(for: raw)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.nyLightGray
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button {
                                    removeImage(raw)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .nyError)
                                }
                                .padding(2)
                            }
                        }
                    }
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(isUploading ? "Uploading…" : "Add Image", systemImage: "photo.badge.plus")
            }
            .disabled(isUploading)
            .onChange(of: photoItem) { _, newValue in
                if let newValue { uploadPhoto(newValue) }
            }
        }
    }

    private func priceField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text("$")
            TextField(title, text: text)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Populate

    private func populate() {
        guard case let .edit(product) = mode, editingProductID == nil else { return }
        editingProductID = product.id
        name = product.name
        description = product.description
        category = product.category
        priceText = String(product.price)
        salePriceText = product.salePrice.map { String($0) } ?? ""
        stockText = String(product.stockQuantity)
        sku = product.sku ?? ""
        tagsText = product.tags.joined(separator: ", ")
        imageURLs = product.imageURLs
        // `isActive` isn't in CatalogProduct (store only lists active products); the
        // store only surfaces active items, so default to true and let the toggle edit it.
        isActive = true
    }

    private var tags: [String] {
        tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    // MARK: - Actions

    private func save() {
        guard let price = Double(priceText), let stock = Int(stockText) else { return }
        let salePrice = Double(salePriceText)
        isSaving = true
        Task {
            do {
                if let id = editingProductID {
                    let request = UpdateProductRequest(
                        name: name, description: description, price: price,
                        salePrice: salePrice, category: category, stockQuantity: stock,
                        isActive: isActive, imageURLs: nil,
                        sku: sku.isEmpty ? nil : sku, weight: nil, tags: tags
                    )
                    let updated = try await adminService.updateProduct(id: id, request)
                    onChange(updated, nil)
                } else {
                    let request = CreateProductRequest(
                        name: name, description: description, price: price,
                        salePrice: salePrice, category: category, stockQuantity: stock,
                        imageURLs: [], sku: sku.isEmpty ? nil : sku, weight: nil, tags: tags
                    )
                    let created = try await adminService.createProduct(request)
                    onChange(created, nil)
                }
                dismiss()
            } catch {
                present(error)
            }
            isSaving = false
        }
    }

    private func delete() {
        guard let id = editingProductID else { return }
        Task {
            do {
                try await adminService.deleteProduct(id: id)
                onChange(nil, id)
                dismiss()
            } catch {
                present(error)
            }
        }
    }

    private func removeImage(_ raw: String) {
        guard let id = editingProductID else { return }
        let remaining = imageURLs.filter { $0 != raw }
        Task {
            do {
                let updated = try await adminService.updateImages(id: id, imageURLs: remaining)
                imageURLs = updated.imageURLs
                onChange(updated, nil)
            } catch { present(error) }
        }
    }

    private func uploadPhoto(_ item: PhotosPickerItem) {
        guard let id = editingProductID else { return }
        isUploading = true
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    errorMessage = "Couldn't read the selected image."
                    showError = true
                    photoItem = nil
                    isUploading = false
                    return
                }
                let (filename, mime) = imageMetadata(for: item)
                let updated = try await adminService.uploadImage(
                    productID: id, data: data, filename: filename, mimeType: mime
                )
                imageURLs = updated.imageURLs
                onChange(updated, nil)
            } catch {
                present(error)
            }
            photoItem = nil
            isUploading = false
        }
    }

    private func imageMetadata(for item: PhotosPickerItem) -> (String, String) {
        if let type = item.supportedContentTypes.first {
            let ext = type.preferredFilenameExtension ?? "jpg"
            let mime = type.preferredMIMEType ?? "image/jpeg"
            return ("upload.\(ext)", mime)
        }
        return ("upload.jpg", "image/jpeg")
    }

    private func present(_ error: Error) {
        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        showError = true
    }
}
