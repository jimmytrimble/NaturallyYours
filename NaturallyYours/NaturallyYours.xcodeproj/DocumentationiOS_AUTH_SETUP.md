# Naturally Yours - iOS Authentication Setup

## 🎉 What You've Got

Your iOS app now has a complete authentication system that connects to your Vapor backend!

### Features
- ✅ **User Registration** - First name, last name, email, password with validation
- ✅ **User Login** - Secure authentication with session cookies
- ✅ **Guest Mode** - Continue shopping without an account
- ✅ **Password Validation** - Live feedback on password requirements
- ✅ **Welcome Screen** - Personalized greeting with user's first name
- ✅ **Account Info** - Display user profile information
- ✅ **Logout** - Secure session termination

## 📁 Files Created

```
Models/
└── User.swift                  # User models and DTOs

Services/
└── AuthService.swift           # API communication and auth state

Views/
├── LoginRegisterView.swift     # Login/register screens
└── HomeView.swift              # Welcome screen after auth
```

## 🚀 Setup Instructions

### 1. Configure Your Backend URL

Open `Services/AuthService.swift` and update the `baseURL`:

```swift
// For local development (simulator)
private let baseURL = "http://localhost:8080"

// For physical device on same network
private let baseURL = "http://YOUR_MAC_IP:8080"  // e.g., "http://192.168.1.5:8080"

// For production
private let baseURL = "https://your-server.com"
```

**Finding your Mac's IP address:**
- Open System Settings → Network
- Look for "IP Address" under your active connection

### 2. Allow Local Network Connections (iOS Simulator)

Add this to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**⚠️ For production:** Remove this and use HTTPS only!

### 3. Start Your Backend Server

```bash
# Make sure your database is running
docker run --name naturally-yours-db \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -e POSTGRES_DB=vapor_database \
  -p 5432:5432 \
  -d postgres:15

# Run migrations
cd path/to/your/vapor/project
swift run NaturallyYoursServer migrate

# Start server
swift run NaturallyYoursServer serve
```

### 4. Run Your iOS App

- Open the project in Xcode
- Select a simulator or device
- Press **⌘ + R** to run

## 🎨 User Flow

1. **App Launch** → Login/Register screen
2. **User chooses:**
   - **Log In** → Enter email/password → Home screen
   - **Sign Up** → Fill registration form → Home screen
   - **Continue as Guest** → Home screen (guest mode)
3. **Home Screen** → Personalized greeting
4. **Log Out** → Returns to login screen

## 📱 Screenshots Preview

### Login Screen
- Naturally Yours logo
- Email and password fields
- "Log In" button
- "Continue as Guest" button
- "Don't have an account? Sign Up" link

### Register Screen
- First name, last name fields
- Email and password fields
- Confirm password field
- Live password validation indicators
- "Create Account" button
- "Already have an account? Log In" link

### Home Screen (Authenticated)
- "Hello, [First Name]!" greeting
- Account information card
  - Full name
  - Email address
- Log Out button

### Home Screen (Guest)
- "Hello, Guest!" greeting
- Info card about guest mode benefits
- "Exit Guest Mode" button

## 🔐 OAuth Integration (Future Enhancement)

To add **Sign in with Apple, Google, Facebook**:

### Sign in with Apple

1. **Add Capability in Xcode:**
   - Select your project → Signing & Capabilities
   - Click "+" → Add "Sign in with Apple"

2. **Install Dependencies:**
   ```swift
   // Add to your Package.swift dependencies
   .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
   ```

3. **Implement Sign in with Apple:**

```swift
import AuthenticationServices

class AuthService: ObservableObject {
    // ... existing code ...
    
    func signInWithApple() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Handle the response and send to your backend
        // Your backend needs to verify the Apple token
    }
}
```

### Google Sign-In

1. **Set up Google Cloud Project:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create OAuth 2.0 credentials for iOS

2. **Add Google Sign-In SDK:**
   ```swift
   .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
   ```

3. **Configure in your backend:**
   - Add endpoint to handle Google OAuth tokens
   - Verify tokens server-side
   - Create/login user based on Google profile

### Facebook Login

1. **Set up Facebook App:**
   - Go to [Facebook Developers](https://developers.facebook.com)
   - Create an app and get App ID

2. **Add Facebook SDK:**
   ```swift
   .package(url: "https://github.com/facebook/facebook-ios-sdk", from: "16.0.0")
   ```

3. **Update Info.plist** with Facebook App ID

### Backend Changes for OAuth

Add these endpoints to your Vapor backend:

```swift
// Routes/AuthRoutes.swift

// Apple Sign-In
users.post("apple-signin") { req async throws -> AuthResponse in
    let token = try req.content.decode(AppleSignInToken.self)
    // Verify Apple token
    // Create or find user
    // Return auth response
}

// Google Sign-In
users.post("google-signin") { req async throws -> AuthResponse in
    let token = try req.content.decode(GoogleSignInToken.self)
    // Verify Google token
    // Create or find user
    // Return auth response
}

// Facebook Login
users.post("facebook-login") { req async throws -> AuthResponse in
    let token = try req.content.decode(FacebookLoginToken.self)
    // Verify Facebook token
    // Create or find user
    // Return auth response
}
```

## 🧪 Testing

### Test User Registration
1. Tap "Sign Up"
2. Fill in:
   - First Name: "John"
   - Last Name: "Doe"
   - Email: "john@example.com"
   - Password: "Test1234"
   - Confirm Password: "Test1234"
3. Should see: "Hello, John!" on home screen

### Test User Login
1. Register a user first (or use one created via backend)
2. Tap "Log In"
3. Enter email and password
4. Should navigate to home screen with personalized greeting

### Test Guest Mode
1. On login screen, tap "Continue as Guest"
2. Should see: "Hello, Guest!" on home screen
3. Should see info card about guest benefits

### Test Logout
1. While logged in, tap "Log Out"
2. Should return to login screen
3. Session should be cleared on backend

## 🐛 Troubleshooting

### "Cannot connect to server"
- ✅ Make sure backend is running: `swift run NaturallyYoursServer serve`
- ✅ Check `baseURL` in `AuthService.swift`
- ✅ For physical devices, use your Mac's IP address
- ✅ Ensure `NSAppTransportSecurity` is configured in Info.plist

### "Invalid response from server"
- ✅ Check backend logs for errors
- ✅ Verify your database is running
- ✅ Ensure migrations have been run

### "Signup/Login failed"
- ✅ Check password meets requirements (8+ chars, uppercase, number)
- ✅ Verify email format is valid
- ✅ Check if email is already registered (for signup)

### Session not persisting
- ✅ Backend must be configured with session middleware
- ✅ Check that cookies are being saved (enabled in `AuthService`)
- ✅ Verify backend's session storage is working

### Password validation not working
- ✅ Must have at least 8 characters
- ✅ Must have at least 1 uppercase letter
- ✅ Must have at least 1 number
- ✅ Passwords must match

## 🎯 Next Steps

### Immediate Enhancements
1. **Add Info.plist** configuration for local networking
2. **Test on physical device** to ensure network connectivity works
3. **Add error handling** improvements (e.g., no internet connection)
4. **Add "Forgot Password"** flow

### Product Features
1. **Product Catalog** - Browse beauty products
2. **Shopping Cart** - Add items to cart
3. **Checkout Flow** - Complete purchases
4. **Order History** - View past orders
5. **User Profile** - Edit account information
6. **Wishlist** - Save favorite products

### UI Polish
1. **Custom color scheme** matching your brand
2. **Product images** and beautiful layouts
3. **Animations** for screen transitions
4. **Loading states** throughout the app
5. **Empty states** for no products, orders, etc.

### Backend Integration
1. **Products API** - Fetch products from backend
2. **Cart API** - Sync cart with backend
3. **Orders API** - Process and track orders
4. **User Profile API** - Update user information
5. **Image Upload** - Product and profile images

## 📚 Code Examples

### Calling Protected Endpoints

Once authenticated, you can call other protected endpoints:

```swift
// In AuthService or a new ProductService

func getProducts() async throws -> [Product] {
    guard let url = URL(string: "\(baseURL)/api/products") else {
        throw AuthError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw AuthError.invalidResponse
    }
    
    return try JSONDecoder().decode([Product].self, from: data)
}
```

### Adding to Cart (Guest or Authenticated)

```swift
struct CartItem: Codable {
    let productID: UUID
    let quantity: Int
}

func addToCart(productID: UUID, quantity: Int) async throws {
    let endpoint = authService.isGuest ? "/api/guest/cart" : "/api/cart"
    
    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
        throw AuthError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let item = CartItem(productID: productID, quantity: quantity)
    request.httpBody = try JSONEncoder().encode(item)
    
    let (_, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
        throw AuthError.serverError("Failed to add to cart")
    }
}
```

## 🔒 Security Best Practices

### Current Implementation ✅
- [x] Passwords sent securely via Basic Auth over HTTPS (use HTTPS in production!)
- [x] Session cookies for authentication
- [x] Password validation on client and server
- [x] Secure password hashing (Bcrypt) on backend

### Production Recommendations
- [ ] Use HTTPS/TLS for all API calls
- [ ] Implement certificate pinning for extra security
- [ ] Add biometric authentication (Face ID/Touch ID)
- [ ] Implement token refresh mechanism
- [ ] Add rate limiting on login attempts
- [ ] Enable email verification
- [ ] Add two-factor authentication (2FA)
- [ ] Implement "Remember Me" securely
- [ ] Add device tracking and management

## 🎊 You're All Set!

Your Naturally Yours app now has a beautiful, functional authentication system ready for your users!

Run the app and start testing. Happy coding! 🚀
