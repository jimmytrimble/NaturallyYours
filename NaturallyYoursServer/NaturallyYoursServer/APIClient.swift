//
//  APIClient.swift
//  NaturallyYours (Client App)
//
//  Use this file in your NaturallyYours client application
//

import Foundation

/// API client for communicating with NaturallyYoursServer
@MainActor
class APIClient: ObservableObject {
    @Published var items: [ItemResponse] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: String = "http://localhost:8080") {
        self.baseURL = URL(string: baseURL)!
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - API Methods
    
    /// Fetch all items from the server
    func fetchItems() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = baseURL.appendingPathComponent("api/items")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = try decoder.decode([ItemResponse].self, from: data)
    }
    
    /// Create a new item on the server
    func createItem(timestamp: Date = Date()) async throws -> ItemResponse {
        isLoading = true
        defer { isLoading = false }
        
        let url = baseURL.appendingPathComponent("api/items")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateItemRequest(timestamp: timestamp)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let item = try decoder.decode(ItemResponse.self, from: data)
        
        // Update local cache
        items.insert(item, at: 0)
        
        return item
    }
    
    /// Delete an item from the server
    func deleteItem(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = baseURL.appendingPathComponent("api/items/\(id.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Update local cache
        items.removeAll { $0.id == id }
    }
    
    /// Check server health
    func checkHealth() async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("health")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }
}

// MARK: - Models

struct ItemResponse: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
}

struct CreateItemRequest: Codable {
    let timestamp: Date?
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Example Usage View

#if DEBUG
import SwiftUI

struct ExampleClientView: View {
    @StateObject private var apiClient = APIClient()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Server Status") {
                    Button("Check Health") {
                        Task {
                            do {
                                let health = try await apiClient.checkHealth()
                                print("Server status: \(health.status)")
                            } catch {
                                print("Health check failed: \(error)")
                            }
                        }
                    }
                }
                
                Section("Items") {
                    ForEach(apiClient.items) { item in
                        VStack(alignment: .leading) {
                            Text(item.timestamp, format: .dateTime)
                            Text(item.id.uuidString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                let item = apiClient.items[index]
                                try? await apiClient.deleteItem(id: item.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("API Client Example")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Item") {
                        Task {
                            try? await apiClient.createItem()
                        }
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Refresh") {
                        Task {
                            try? await apiClient.fetchItems()
                        }
                    }
                }
            }
            .task {
                try? await apiClient.fetchItems()
            }
            .overlay {
                if apiClient.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

#Preview {
    ExampleClientView()
}
#endif
