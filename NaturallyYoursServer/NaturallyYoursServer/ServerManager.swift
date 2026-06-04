//
//  ServerManager.swift
//  NaturallyYoursServer
//
//  Created by Jamiel Trimble II on 5/25/26.
//

import Foundation
import Vapor
import SwiftData

/// Manages the Vapor server instance and routing
@MainActor
class ServerManager: ObservableObject {
    @Published var isRunning = false
    @Published var serverURL: String = "http://localhost:8080"
    
    private var app: Application?
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func startServer() async throws {
        guard !isRunning else { return }
        
        // Create Vapor application
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        self.app = app
        
        // Configure routes
        try configureRoutes(app)
        
        // Start server on background thread
        Task.detached { [weak self] in
            do {
                try app.run()
            } catch {
                await MainActor.run {
                    self?.isRunning = false
                }
                print("Server error: \(error)")
            }
        }
        
        isRunning = true
        print("✅ Server started at \(serverURL)")
    }
    
    func stopServer() {
        app?.shutdown()
        app = nil
        isRunning = false
        print("🛑 Server stopped")
    }
    
    private func configureRoutes(_ app: Application) throws {
        // CORS configuration for cross-origin requests
        let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .PATCH],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
        )
        let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
        app.middleware.use(corsMiddleware)
        
        // Health check endpoint
        app.get("health") { req in
            return ["status": "healthy", "timestamp": Date().ISO8601Format()]
        }
        
        // Items endpoints
        let items = app.grouped("api", "items")
        
        // GET all items
        items.get { [weak self] req async throws -> [ItemDTO] in
            guard let self = self else { throw Abort(.internalServerError) }
            return try await self.getAllItems()
        }
        
        // GET specific item
        items.get(":id") { [weak self] req async throws -> ItemDTO in
            guard let self = self,
                  let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString) else {
                throw Abort(.badRequest)
            }
            
            guard let item = try await self.getItem(id: id) else {
                throw Abort(.notFound)
            }
            return item
        }
        
        // POST new item
        items.post { [weak self] req async throws -> ItemDTO in
            guard let self = self else { throw Abort(.internalServerError) }
            let dto = try req.content.decode(CreateItemDTO.self)
            return try await self.createItem(timestamp: dto.timestamp ?? Date())
        }
        
        // DELETE item
        items.delete(":id") { [weak self] req async throws -> HTTPStatus in
            guard let self = self,
                  let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString) else {
                throw Abort(.badRequest)
            }
            
            try await self.deleteItem(id: id)
            return .noContent
        }
        
        print("📋 Routes configured:")
        print("   GET  /health")
        print("   GET  /api/items")
        print("   GET  /api/items/:id")
        print("   POST /api/items")
        print("   DELETE /api/items/:id")
    }
    
    // MARK: - SwiftData Operations
    
    private func getAllItems() async throws -> [ItemDTO] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let items = try context.fetch(descriptor)
        return items.map { ItemDTO(from: $0) }
    }
    
    private func getItem(id: UUID) async throws -> ItemDTO? {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        
        guard let item = try context.fetch(descriptor).first else {
            return nil
        }
        return ItemDTO(from: item)
    }
    
    private func createItem(timestamp: Date) async throws -> ItemDTO {
        let context = ModelContext(modelContainer)
        let newItem = Item(timestamp: timestamp)
        context.insert(newItem)
        try context.save()
        return ItemDTO(from: newItem)
    }
    
    private func deleteItem(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        
        guard let item = try context.fetch(descriptor).first else {
            throw Abort(.notFound)
        }
        
        context.delete(item)
        try context.save()
    }
}

// MARK: - Data Transfer Objects

struct ItemDTO: Content {
    let id: UUID
    let timestamp: Date
    
    init(from item: Item) {
        self.id = item.id
        self.timestamp = item.timestamp
    }
}

struct CreateItemDTO: Content {
    let timestamp: Date?
}
