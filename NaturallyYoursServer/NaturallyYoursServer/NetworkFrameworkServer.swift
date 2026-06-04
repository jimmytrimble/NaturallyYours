//
//  NetworkFrameworkServer.swift
//  NaturallyYoursServer
//
//  Alternative lightweight server using Apple's Network framework
//  Use this if you prefer not to add Vapor dependency
//

import Foundation
import Network
import SwiftData

/// Lightweight HTTP server using Apple's Network framework
@MainActor
class NetworkFrameworkServer: ObservableObject {
    @Published var isRunning = false
    @Published var serverURL: String = "http://localhost:8080"
    
    private var listener: NWListener?
    private let modelContainer: ModelContainer
    private let port: NWEndpoint.Port = 8080
    private var activeConnections: [NWConnection] = []
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func start() throws {
        guard !isRunning else { return }
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        let listener = try NWListener(using: parameters, on: port)
        self.listener = listener
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("✅ Server started on port \(self?.port.rawValue ?? 0)")
                case .failed(let error):
                    print("❌ Server failed: \(error)")
                    self?.isRunning = false
                case .cancelled:
                    self?.isRunning = false
                    print("🛑 Server cancelled")
                default:
                    break
                }
            }
        }
        
        listener.start(queue: .global(qos: .userInitiated))
    }
    
    func stop() {
        listener?.cancel()
        activeConnections.forEach { $0.cancel() }
        activeConnections.removeAll()
        isRunning = false
    }
    
    private func handleConnection(_ connection: NWConnection) {
        activeConnections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            if case .cancelled = state {
                self?.activeConnections.removeAll { $0 === connection }
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(from: connection)
    }
    
    private func receiveRequest(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                let request = self.parseHTTPRequest(data)
                Task {
                    let response = await self.handleHTTPRequest(request)
                    self.sendResponse(response, to: connection)
                }
            }
            
            if isComplete || error != nil {
                connection.cancel()
            } else {
                self.receiveRequest(from: connection)
            }
        }
    }
    
    private func parseHTTPRequest(_ data: Data) -> HTTPRequest {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return HTTPRequest(method: "", path: "", headers: [:], body: nil)
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return HTTPRequest(method: "", path: "", headers: [:], body: nil)
        }
        
        let components = requestLine.components(separatedBy: " ")
        let method = components.first ?? ""
        let path = components.count > 1 ? components[1] : "/"
        
        var headers: [String: String] = [:]
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            
            if index > 0 {
                let parts = line.components(separatedBy: ": ")
                if parts.count == 2 {
                    headers[parts[0]] = parts[1]
                }
            }
        }
        
        var body: Data?
        if bodyStartIndex < lines.count {
            let bodyString = lines[bodyStartIndex...].joined(separator: "\r\n")
            body = bodyString.data(using: .utf8)
        }
        
        return HTTPRequest(method: method, path: path, headers: headers, body: body)
    }
    
    private func handleHTTPRequest(_ request: HTTPRequest) async -> HTTPResponse {
        // CORS headers
        if request.method == "OPTIONS" {
            return HTTPResponse(
                statusCode: 204,
                headers: corsHeaders(),
                body: nil
            )
        }
        
        // Route handling
        if request.path == "/health" && request.method == "GET" {
            return await handleHealth()
        } else if request.path == "/api/items" && request.method == "GET" {
            return await handleGetAllItems()
        } else if request.path == "/api/items" && request.method == "POST" {
            return await handleCreateItem(request)
        } else if request.path.hasPrefix("/api/items/") && request.method == "GET" {
            let id = String(request.path.dropFirst("/api/items/".count))
            return await handleGetItem(id)
        } else if request.path.hasPrefix("/api/items/") && request.method == "DELETE" {
            let id = String(request.path.dropFirst("/api/items/".count))
            return await handleDeleteItem(id)
        } else {
            return HTTPResponse(
                statusCode: 404,
                headers: corsHeaders(),
                body: jsonData(["error": "Not found"])
            )
        }
    }
    
    // MARK: - Route Handlers
    
    private func handleHealth() async -> HTTPResponse {
        let health = ["status": "healthy", "timestamp": Date().ISO8601Format()]
        return HTTPResponse(
            statusCode: 200,
            headers: jsonHeaders(),
            body: jsonData(health)
        )
    }
    
    private func handleGetAllItems() async -> HTTPResponse {
        do {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            let items = try context.fetch(descriptor)
            let dtos = items.map { ItemDTO(from: $0) }
            
            return HTTPResponse(
                statusCode: 200,
                headers: jsonHeaders(),
                body: try JSONEncoder().encode(dtos)
            )
        } catch {
            return HTTPResponse(
                statusCode: 500,
                headers: jsonHeaders(),
                body: jsonData(["error": error.localizedDescription])
            )
        }
    }
    
    private func handleGetItem(_ idString: String) async -> HTTPResponse {
        guard let id = UUID(uuidString: idString) else {
            return HTTPResponse(
                statusCode: 400,
                headers: jsonHeaders(),
                body: jsonData(["error": "Invalid ID"])
            )
        }
        
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<Item> { item in item.id == id }
            var descriptor = FetchDescriptor(predicate: predicate)
            descriptor.fetchLimit = 1
            
            guard let item = try context.fetch(descriptor).first else {
                return HTTPResponse(
                    statusCode: 404,
                    headers: jsonHeaders(),
                    body: jsonData(["error": "Item not found"])
                )
            }
            
            let dto = ItemDTO(from: item)
            return HTTPResponse(
                statusCode: 200,
                headers: jsonHeaders(),
                body: try JSONEncoder().encode(dto)
            )
        } catch {
            return HTTPResponse(
                statusCode: 500,
                headers: jsonHeaders(),
                body: jsonData(["error": error.localizedDescription])
            )
        }
    }
    
    private func handleCreateItem(_ request: HTTPRequest) async -> HTTPResponse {
        do {
            let context = ModelContext(modelContainer)
            let newItem = Item(timestamp: Date())
            context.insert(newItem)
            try context.save()
            
            let dto = ItemDTO(from: newItem)
            return HTTPResponse(
                statusCode: 201,
                headers: jsonHeaders(),
                body: try JSONEncoder().encode(dto)
            )
        } catch {
            return HTTPResponse(
                statusCode: 500,
                headers: jsonHeaders(),
                body: jsonData(["error": error.localizedDescription])
            )
        }
    }
    
    private func handleDeleteItem(_ idString: String) async -> HTTPResponse {
        guard let id = UUID(uuidString: idString) else {
            return HTTPResponse(
                statusCode: 400,
                headers: jsonHeaders(),
                body: jsonData(["error": "Invalid ID"])
            )
        }
        
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<Item> { item in item.id == id }
            var descriptor = FetchDescriptor(predicate: predicate)
            descriptor.fetchLimit = 1
            
            guard let item = try context.fetch(descriptor).first else {
                return HTTPResponse(
                    statusCode: 404,
                    headers: jsonHeaders(),
                    body: jsonData(["error": "Item not found"])
                )
            }
            
            context.delete(item)
            try context.save()
            
            return HTTPResponse(
                statusCode: 204,
                headers: corsHeaders(),
                body: nil
            )
        } catch {
            return HTTPResponse(
                statusCode: 500,
                headers: jsonHeaders(),
                body: jsonData(["error": error.localizedDescription])
            )
        }
    }
    
    // MARK: - Helpers
    
    private func sendResponse(_ response: HTTPResponse, to connection: NWConnection) {
        let responseData = response.toData()
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func corsHeaders() -> [String: String] {
        [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        ]
    }
    
    private func jsonHeaders() -> [String: String] {
        var headers = corsHeaders()
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    private func jsonData(_ dict: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: dict)
    }
}

// MARK: - Supporting Types

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data?
}

struct HTTPResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: Data?
    
    func toData() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(statusMessage)\r\n"
        
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        
        if let body = body {
            response += "Content-Length: \(body.count)\r\n"
        }
        
        response += "\r\n"
        
        var data = response.data(using: .utf8) ?? Data()
        if let body = body {
            data.append(body)
        }
        
        return data
    }
    
    private var statusMessage: String {
        switch statusCode {
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}

struct ItemDTO: Codable {
    let id: UUID
    let timestamp: Date
    
    init(from item: Item) {
        self.id = item.id
        self.timestamp = item.timestamp
    }
}
