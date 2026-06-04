//
//  NaturallyYoursIntegrationExample.swift
//  Example integration for your NaturallyYours app
//
//  Copy the relevant parts to your NaturallyYours project
//

import SwiftUI

// MARK: - Example 1: Simple Integration

/// Basic example showing how to use the API client
struct SimpleNaturallyYoursView: View {
    @StateObject private var apiClient = APIClient(baseURL: "http://localhost:8080")
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(apiClient.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Created:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.timestamp, format: .dateTime)
                            .font(.headline)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            try? await apiClient.deleteItem(id: apiClient.items[index].id)
                        }
                    }
                }
            }
            .navigationTitle("Naturally Yours")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        Task {
                            try? await apiClient.createItem()
                        }
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task {
                            try? await apiClient.fetchItems()
                        }
                    }
                }
            }
            .task {
                // Load items when view appears
                try? await apiClient.fetchItems()
            }
            .refreshable {
                // Pull to refresh
                try? await apiClient.fetchItems()
            }
        }
    }
}

// MARK: - Example 2: Advanced Integration with Error Handling

/// More robust example with proper error handling and loading states
struct AdvancedNaturallyYoursView: View {
    @StateObject private var viewModel = NaturallyYoursViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task {
                            await viewModel.loadItems()
                        }
                    }
                } else {
                    itemsList
                }
            }
            .navigationTitle("Naturally Yours")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        Task {
                            await viewModel.addItem()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task {
                            await viewModel.loadItems()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadItems()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    @ViewBuilder
    private var itemsList: some View {
        List {
            ForEach(viewModel.items) { item in
                ItemRow(item: item)
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteItems(at: indexSet)
                }
            }
        }
        .refreshable {
            await viewModel.loadItems()
        }
        .overlay {
            if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "tray",
                    description: Text("Add your first item to get started")
                )
            }
        }
    }
}

struct ItemRow: View {
    let item: ItemResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.timestamp, format: .dateTime)
                .font(.headline)
            
            Text(item.id.uuidString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - View Model

@MainActor
class NaturallyYoursViewModel: ObservableObject {
    @Published var items: [ItemResponse] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    private let apiClient: APIClient
    
    init(serverURL: String = "http://localhost:8080") {
        self.apiClient = APIClient(baseURL: serverURL)
    }
    
    func loadItems() async {
        isLoading = true
        error = nil
        
        do {
            try await apiClient.fetchItems()
            items = apiClient.items
        } catch {
            self.error = error
            self.showError = true
        }
        
        isLoading = false
    }
    
    func addItem() async {
        isLoading = true
        error = nil
        
        do {
            let newItem = try await apiClient.createItem()
            items.insert(newItem, at: 0)
        } catch {
            self.error = error
            self.showError = true
        }
        
        isLoading = false
    }
    
    func deleteItems(at indexSet: IndexSet) async {
        for index in indexSet {
            let item = items[index]
            
            do {
                try await apiClient.deleteItem(id: item.id)
                items.remove(at: index)
            } catch {
                self.error = error
                self.showError = true
                break
            }
        }
    }
}

// MARK: - Example 3: Settings View with Server Configuration

struct ServerSettingsView: View {
    @AppStorage("serverURL") private var serverURL = "http://localhost:8080"
    @State private var tempURL = ""
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    
    var body: some View {
        Form {
            Section("Server Configuration") {
                TextField("Server URL", text: $tempURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onAppear {
                        tempURL = serverURL
                    }
                
                Button("Save") {
                    serverURL = tempURL
                }
                .disabled(tempURL.isEmpty)
            }
            
            Section("Connection") {
                HStack {
                    Text("Status:")
                    Spacer()
                    connectionStatusView
                }
                
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTestingConnection)
            }
            
            Section("Presets") {
                Button("Local (localhost:8080)") {
                    tempURL = "http://localhost:8080"
                }
                
                Button("Local Network") {
                    tempURL = "http://192.168.1.100:8080"
                }
                
                Button("Production") {
                    tempURL = "https://api.naturallyyours.com"
                }
            }
        }
        .navigationTitle("Server Settings")
    }
    
    @ViewBuilder
    private var connectionStatusView: some View {
        if isTestingConnection {
            ProgressView()
        } else {
            HStack(spacing: 4) {
                Circle()
                    .fill(connectionStatus.color)
                    .frame(width: 8, height: 8)
                Text(connectionStatus.text)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = .unknown
        
        Task {
            do {
                let client = APIClient(baseURL: tempURL)
                _ = try await client.checkHealth()
                connectionStatus = .connected
            } catch {
                connectionStatus = .failed
            }
            
            isTestingConnection = false
        }
    }
}

enum ConnectionStatus {
    case unknown, connected, failed
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .connected: return .green
        case .failed: return .red
        }
    }
    
    var text: String {
        switch self {
        case .unknown: return "Unknown"
        case .connected: return "Connected"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Example 4: Main App Structure

@main
struct NaturallyYoursApp: App {
    @AppStorage("serverURL") private var serverURL = "http://localhost:8080"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(APIClient(baseURL: serverURL))
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var apiClient: APIClient
    
    var body: some View {
        TabView {
            AdvancedNaturallyYoursView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
            
            ServerSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Previews

#Preview("Simple") {
    SimpleNaturallyYoursView()
}

#Preview("Advanced") {
    AdvancedNaturallyYoursView()
}

#Preview("Settings") {
    NavigationStack {
        ServerSettingsView()
    }
}
