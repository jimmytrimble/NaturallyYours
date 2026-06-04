# NaturallyYoursServer

A Swift-based backend server for the NaturallyYours application using Vapor and SwiftData.

## Overview

This project serves as a local or deployed backend server that provides REST API endpoints for your NaturallyYours client application. It uses:

- **Vapor** - Modern Swift web framework
- **SwiftData** - Apple's data persistence framework
- **SwiftUI** - Server management interface

## Setup

### 1. Install Vapor (if deploying standalone)

```bash
brew install vapor
```

### 2. Add Vapor Package Dependency

In Xcode:
1. Go to **File → Add Package Dependencies**
2. Enter: `https://github.com/vapor/vapor.git`
3. Select version **4.0.0** or later
4. Click **Add Package**

### 3. Run the Server

1. Build and run the project in Xcode
2. Click the **"Start Server"** button in the UI
3. The server will start at `http://localhost:8080`

## API Endpoints

### Health Check
```
GET /health
```
Returns server health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-05-25T10:30:00Z"
}
```

### Get All Items
```
GET /api/items
```
Returns all items sorted by timestamp (newest first).

**Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": "2026-05-25T10:30:00Z"
  }
]
```

### Get Single Item
```
GET /api/items/:id
```
Returns a specific item by UUID.

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-05-25T10:30:00Z"
}
```

### Create Item
```
POST /api/items
Content-Type: application/json
```

**Request Body:**
```json
{
  "timestamp": "2026-05-25T10:30:00Z"  // Optional, defaults to current time
}
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-05-25T10:30:00Z"
}
```

### Delete Item
```
DELETE /api/items/:id
```
Deletes the specified item.

**Response:** `204 No Content`

## Using in Your NaturallyYours Client App

### 1. Add the API Client

Copy `APIClient.swift` to your NaturallyYours project.

### 2. Basic Usage

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

### 3. Create an Item

```swift
Button("Add Item") {
    Task {
        try await apiClient.createItem()
    }
}
```

### 4. Delete an Item

```swift
Button("Delete") {
    Task {
        try await apiClient.deleteItem(id: item.id)
    }
}
```

## Architecture

```
┌─────────────────────────────────────┐
│   NaturallyYours Client App         │
│   (Your main application)           │
│                                     │
│   Uses: APIClient.swift             │
└──────────────┬──────────────────────┘
               │
               │ HTTP/REST API
               │
┌──────────────▼──────────────────────┐
│   NaturallyYoursServer              │
│                                     │
│   ┌─────────────────────────────┐  │
│   │  Vapor Web Server           │  │
│   │  (Port 8080)                │  │
│   └──────────┬──────────────────┘  │
│              │                      │
│   ┌──────────▼──────────────────┐  │
│   │  SwiftData Storage          │  │
│   │  (Local SQLite Database)    │  │
│   └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Configuration

### Change Server Port

In `ServerManager.swift`, modify the app configuration:

```swift
app.http.server.configuration.port = 8080  // Change this
```

### Change Base URL in Client

In your NaturallyYours app:

```swift
let apiClient = APIClient(baseURL: "http://your-server-ip:8080")
```

## Deployment Options

### Option 1: Local Development (Default)
- Run the server app on your Mac
- Client connects to `http://localhost:8080`
- Great for development and testing

### Option 2: Network Server
- Run the server on a Mac on your network
- Client connects to `http://192.168.x.x:8080`
- Allows multiple devices to connect

### Option 3: Cloud Deployment
- Deploy to a cloud provider (e.g., DigitalOcean, AWS, Heroku)
- Client connects to `https://your-domain.com`
- Production-ready solution

## Security Considerations

⚠️ **This is a basic implementation for development.** For production:

1. **Add Authentication**: Implement token-based auth (JWT)
2. **Use HTTPS**: Enable TLS/SSL certificates
3. **Add Rate Limiting**: Prevent abuse
4. **Validate Input**: Add comprehensive validation
5. **Error Handling**: Improve error responses
6. **Database Backups**: Implement regular backups

## Troubleshooting

### Server Won't Start
- Check if port 8080 is already in use
- Try a different port
- Check firewall settings

### Client Can't Connect
- Ensure server is running
- Verify the base URL is correct
- Check network connectivity
- Disable any VPN that might block local connections

### CORS Errors
- The server includes CORS middleware
- If issues persist, check the CORS configuration in `ServerManager.swift`

## Next Steps

1. **Extend the Data Model**: Add more properties to `Item` or create new models
2. **Add Authentication**: Implement user accounts and JWT tokens
3. **Add File Upload**: Support images or documents
4. **WebSocket Support**: Add real-time updates
5. **Database Migration**: Set up proper migrations for schema changes

## License

[Your License Here]
