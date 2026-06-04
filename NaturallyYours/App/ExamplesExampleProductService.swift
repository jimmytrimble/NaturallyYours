//
//  ExampleProductService.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/28/26.
//
//  This is an EXAMPLE showing how to build on top of the authentication system.
//  Use this as a template for creating your product catalog, cart, orders, etc.

import Foundation

// MARK: - Product Models

struct Product: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let category: String
    let imageURL: String?
    let inStock: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case category
        case imageURL = "image_url"
        case inStock = "in_stock"
    }
}

struct ProductCategory: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
}

// MARK: - Product Service

@MainActor
class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [ProductCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var baseURL: String {
        AppConfiguration.apiBaseURL
    }
    
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = .shared
        return URLSession(configuration: config)
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async throws {
        guard let url = URL(string: "\(baseURL)/api/products") else {
            throw AuthError.invalidURL
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                self.products = try decoder.decode([Product].self, from: data)
            } else {
                throw AuthError.serverError("Failed to fetch products")
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Product by ID
    
    func fetchProduct(id: UUID) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/api/products/\(id.uuidString)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Product.self, from: data)
    }
    
    // MARK: - Search Products
    
    func searchProducts(query: String) async throws -> [Product] {
        guard let url = URL(string: "\(baseURL)/api/products/search?q=\(query)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Product].self, from: data)
    }
}

// MARK: - Example Shopping Cart Service

@MainActor
class CartService: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var total: Double = 0.0
    
    private var baseURL: String {
        AppConfiguration.apiBaseURL
    }
    
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = .shared
        return URLSession(configuration: config)
    }
    
    func addToCart(product: Product, quantity: Int = 1) async throws {
        // For authenticated users
        guard let url = URL(string: "\(baseURL)/api/cart/add") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AddToCartRequest(productID: product.id, quantity: quantity)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to add to cart")
        }
        
        // Refresh cart
        try await fetchCart()
    }
    
    func fetchCart() async throws {
        guard let url = URL(string: "\(baseURL)/api/cart") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }
        
        let cart = try JSONDecoder().decode(Cart.self, from: data)
        self.items = cart.items
        self.total = cart.total
    }
    
    func removeFromCart(itemID: UUID) async throws {
        guard let url = URL(string: "\(baseURL)/api/cart/items/\(itemID.uuidString)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthError.serverError("Failed to remove item")
        }
        
        try await fetchCart()
    }
    
    func checkout() async throws -> Order {
        guard let url = URL(string: "\(baseURL)/api/cart/checkout") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Checkout failed")
        }
        
        let order = try JSONDecoder().decode(Order.self, from: data)
        
        // Clear cart after successful checkout
        self.items = []
        self.total = 0.0
        
        return order
    }
}

// MARK: - Supporting Types

struct CartItem: Codable, Identifiable {
    let id: UUID
    let product: Product
    let quantity: Int
    let subtotal: Double
}

struct Cart: Codable {
    let items: [CartItem]
    let total: Double
}

struct AddToCartRequest: Codable {
    let productID: UUID
    let quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case quantity
    }
}

struct Order: Codable, Identifiable {
    let id: UUID
    let items: [OrderItem]
    let total: Double
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case items
        case total
        case status
        case createdAt = "created_at"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: UUID
    let product: Product
    let quantity: Int
    let price: Double
}

// MARK: - Example SwiftUI Views

#if DEBUG
import SwiftUI

// Example Product List View
struct ProductListView: View {
    @StateObject private var productService = ProductService()
    @StateObject private var cartService = CartService()
    
    var body: some View {
        NavigationStack {
            Group {
                if productService.isLoading {
                    ProgressView("Loading products...")
                } else if productService.products.isEmpty {
                    ContentUnavailableView(
                        "No Products",
                        systemImage: "cart.badge.questionmark",
                        description: Text("No products available at this time")
                    )
                } else {
                    List(productService.products) { product in
                        ProductRow(
                            product: product,
                            onAddToCart: {
                                Task {
                                    try? await cartService.addToCart(product: product)
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("Products")
            .task {
                try? await productService.fetchProducts()
            }
        }
    }
}

// Example Product Row
struct ProductRow: View {
    let product: Product
    let onAddToCart: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            Button {
                onAddToCart()
            } label: {
                Image(systemName: "cart.fill.badge.plus")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.vertical, 4)
    }
}

// Example Cart View
struct CartView: View {
    @StateObject private var cartService = CartService()
    @State private var showingCheckout = false
    
    var body: some View {
        NavigationStack {
            Group {
                if cartService.items.isEmpty {
                    ContentUnavailableView(
                        "Your Cart is Empty",
                        systemImage: "cart",
                        description: Text("Add some products to get started")
                    )
                } else {
                    List {
                        ForEach(cartService.items) { item in
                            CartItemRow(item: item) {
                                Task {
                                    try? await cartService.removeFromCart(itemID: item.id)
                                }
                            }
                        }
                        
                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("$\(cartService.total, specifier: "%.2f")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping Cart")
            .toolbar {
                if !cartService.items.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Checkout") {
                            showingCheckout = true
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .task {
                try? await cartService.fetchCart()
            }
            .sheet(isPresented: $showingCheckout) {
                CheckoutView(cartService: cartService)
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.headline)
                
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(item.subtotal, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Text("Remove")
                        .font(.caption)
                }
            }
        }
    }
}

struct CheckoutView: View {
    @ObservedObject var cartService: CartService
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var orderComplete = false
    @State private var order: Order?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if orderComplete, let order = order {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        Text("Order Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Order #\(order.id.uuidString.prefix(8))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Continue Shopping") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                } else {
                    Text("Checkout")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Total: $\(cartService.total, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await processCheckout()
                        }
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Place Order")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isProcessing)
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !orderComplete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func processCheckout() async {
        isProcessing = true
        
        do {
            let completedOrder = try await cartService.checkout()
            self.order = completedOrder
            self.orderComplete = true
        } catch {
            // Handle error
            print("Checkout failed: \(error)")
        }
        
        isProcessing = false
    }
}

#Preview {
    ProductListView()
}

#Preview("Cart") {
    CartView()
}

#endif
