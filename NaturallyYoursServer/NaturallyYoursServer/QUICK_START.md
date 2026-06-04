# Quick Start Guide: NaturallyYours Server Setup

## 🎯 What You Have Now

Your NaturallyYoursServer project has been transformed into a **REST API backend** that can serve data to your NaturallyYours client application.

## 📦 Files Created

| File | Purpose |
|------|---------|
| `ServerManager.swift` | Vapor-based server (recommended) |
| `NetworkFrameworkServer.swift` | Lightweight alternative using Apple's Network framework |
| `APIClient.swift` | Client code for NaturallyYours app to connect to server |
| `NaturallyYoursIntegrationExample.swift` | Complete examples of how to use the API in your app |
| `README.md` | Full documentation |
| `SERVER_OPTIONS.md` | Comparison of server options |

## 🚀 Quick Setup (5 Minutes)

### Step 1: Choose Your Server Implementation

**Option A: Vapor (Recommended)**
1. In Xcode: File → Add Package Dependencies
2. Add: `https://github.com/vapor/vapor.git`
3. Select version 4.0.0+
4. Uses: `ServerManager.swift`

**Option B: Network Framework (No Dependencies)**
1. No setup needed - uses Apple's native framework
2. Uses: `NetworkFrameworkServer.swift`
3. In `ContentView.swift`, change `ServerManager` to `NetworkFrameworkServer`

### Step 2: Run the Server

1. Build and run NaturallyYoursServer project
2. Click "Start Server" button
3. Server runs at `http://localhost:8080`

### Step 3: Connect Your NaturallyYours App

1. Copy `APIClient.swift` to your NaturallyYours project
2. Use one of the examples from `NaturallyYoursIntegrationExample.swift`
3. Basic usage:

```swift
import SwiftUI

struct YourView: View {
    @StateObject private var apiClient = APIClient()
    
    var body: some View {
        List(apiClient.items) { item in
            Text(item.timestamp, format: .dateTime)
        }
        .task {
            try? await apiClient.fetchItems()
        }
    }
}
```

## 🌐 API Endpoints Available

```
GET    /health                 - Health check
GET    /api/items             - Get all items
GET    /api/items/:id         - Get specific item
POST   /api/items             - Create new item
DELETE /api/items/:id         - Delete item
```

## 💡 Common Scenarios

### Scenario 1: Local Development (Same Machine)
- Server URL: `http://localhost:8080`
- Run both apps on same Mac
- Perfect for development

### Scenario 2: Multiple Devices on Same Network
- Find server Mac's IP: System Settings → Network
- Server URL: `http://192.168.1.100:8080` (use actual IP)
- Run server on Mac, client on iPad/iPhone/Mac

### Scenario 3: Production Deployment
- Deploy server to cloud (AWS, DigitalOcean, etc.)
- Server URL: `https://your-domain.com`
- Add authentication and HTTPS

## 🔧 Customization

### Change Server Port

In `ServerManager.swift` (Vapor):
```swift
app.http.server.configuration.port = 3000  // Change to desired port
```

In `NetworkFrameworkServer.swift`:
```swift
private let port: NWEndpoint.Port = 3000  // Change to desired port
```

### Add Custom Data Fields

1. Update `Item.swift`:
```swift
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var title: String  // Add this
    var content: String  // Add this
    
    init(timestamp: Date, title: String, content: String) {
        self.id = UUID()
        self.timestamp = timestamp
        self.title = title
        self.content = content
    }
}
```

2. Update DTOs in server files:
```swift
struct ItemDTO: Content {
    let id: UUID
    let timestamp: Date
    let title: String
    let content: String
    
    init(from item: Item) {
        self.id = item.id
        self.timestamp = item.timestamp
        self.title = item.title
        self.content = item.content
    }
}
```

3. Update client `APIClient.swift`:
```swift
struct ItemResponse: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let title: String
    let content: String
}
```

## 🐛 Troubleshooting

### Server Won't Start
- **Check port 8080 is free**: `lsof -i :8080`
- **Try different port**: Change port number in server code
- **Check firewall**: System Settings → Network → Firewall

### Client Can't Connect
- ✅ Verify server is running (green indicator)
- ✅ Check server URL is correct
- ✅ Try `http://localhost:8080/health` in browser
- ✅ Ensure no VPN is blocking connection

### CORS Errors
- Already configured in both server implementations
- If issues persist, check browser console for details

### Build Errors
- **Vapor**: Make sure package dependency is added
- **Network Framework**: No dependencies needed

## 📱 Next Steps

1. **Extend Your Model**
   - Add more properties to `Item`
   - Create additional model types
   - Implement relationships

2. **Add Authentication**
   - Implement JWT tokens
   - Add user accounts
   - Secure endpoints

3. **Enhance UI**
   - Add search functionality
   - Implement filters and sorting
   - Create custom views

4. **Deploy to Production**
   - Set up HTTPS/SSL
   - Configure database backups
   - Add logging and monitoring

## 📚 Resources

- [Vapor Documentation](https://docs.vapor.codes)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Network Framework](https://developer.apple.com/documentation/network)

## 💬 Example Implementation Patterns

### Pattern 1: ViewModel-Based Architecture
See `NaturallyYoursViewModel` in `NaturallyYoursIntegrationExample.swift`

### Pattern 2: Environment Object
```swift
@main
struct NaturallyYoursApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(APIClient())
        }
    }
}
```

### Pattern 3: Dependency Injection
```swift
struct ContentView: View {
    let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
}
```

## ✅ Success Checklist

- [ ] Server project builds successfully
- [ ] Can start server with button click
- [ ] Server shows green "Running" indicator
- [ ] Can access `http://localhost:8080/health` in browser
- [ ] APIClient.swift copied to NaturallyYours project
- [ ] Client can fetch items successfully
- [ ] Can create new items from client
- [ ] Can delete items from client

---

**You're all set!** 🎉

Your NaturallyYoursServer is now a fully functional REST API backend ready to serve your NaturallyYours application.
