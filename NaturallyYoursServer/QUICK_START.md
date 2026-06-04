# Quick Start Guide - Naturally Yours Backend

This guide will help you get your authentication system up and running quickly.

## Step 1: Set Up PostgreSQL Database

### Option A: Using Docker (Recommended for Development)

```bash
docker run --name naturally-yours-db \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -e POSTGRES_DB=vapor_database \
  -p 5432:5432 \
  -d postgres:15
```

### Option B: Using Homebrew (macOS)

```bash
brew install postgresql@15
brew services start postgresql@15

# Create database
createdb vapor_database
```

## Step 2: Configure Environment

Create a `.env` file in your project root:

```env
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=vapor_username
DATABASE_PASSWORD=vapor_password
DATABASE_NAME=vapor_database
```

Or set environment variables directly:

```bash
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_USERNAME=vapor_username
export DATABASE_PASSWORD=vapor_password
export DATABASE_NAME=vapor_database
```

## Step 3: Run Migrations

### First Time Setup

1. **Uncomment the default super admin migration** in `configure.swift`:

```swift
app.migrations.add(CreateDefaultSuperAdmin())
```

2. **Run migrations:**

```bash
swift run NaturallyYoursServer migrate
```

This will create:
- Users table
- Admins table
- Session storage
- Your first super admin account

3. **After migrations complete**, you'll see:

```
✅ Default super admin created!
📧 Email: admin@naturallyyours.com
🔑 Password: ChangeMe123!
⚠️  IMPORTANT: Change this password immediately after first login!
```

4. **Comment out the super admin migration** in `configure.swift` to prevent creating duplicates:

```swift
// app.migrations.add(CreateDefaultSuperAdmin())
```

## Step 4: Start the Server

```bash
swift run NaturallyYoursServer serve
```

Your server should now be running on `http://localhost:8080`

## Step 5: Test Your Setup

### Test 1: Create a User Account

```bash
curl -X POST http://localhost:8080/api/auth/users/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "SecurePass123",
    "confirmPassword": "SecurePass123"
  }' \
  -c cookies.txt \
  -v
```

### Test 2: Log In as User

```bash
curl -X POST http://localhost:8080/api/auth/users/login \
  -H "Content-Type: application/json" \
  -u "test@example.com:SecurePass123" \
  -b cookies.txt \
  -c cookies.txt \
  -v
```

### Test 3: Get Current User Profile

```bash
curl -X GET http://localhost:8080/api/auth/users/me \
  -b cookies.txt
```

### Test 4: Log In as Admin

```bash
curl -X POST http://localhost:8080/api/auth/admins/login \
  -H "Content-Type: application/json" \
  -u "admin@naturallyyours.com:ChangeMe123!" \
  -c admin-cookies.txt \
  -v
```

### Test 5: Create Another Admin (Super Admin Only)

```bash
curl -X POST http://localhost:8080/api/auth/admins/create \
  -H "Content-Type: application/json" \
  -b admin-cookies.txt \
  -d '{
    "name": "Moderator User",
    "email": "moderator@naturallyyours.com",
    "password": "ModPass123!",
    "confirmPassword": "ModPass123!",
    "role": "moderator"
  }'
```

## Step 6: Change Default Admin Password

After confirming the admin login works, you should immediately change the password:

You can create a password change endpoint, or update directly in the database:

```sql
-- Connect to your database
psql -U vapor_username -d vapor_database

-- Update password (using a new bcrypt hash)
-- Generate hash for your new password first
```

Or create a simple route to change passwords (recommended to add this functionality).

## Common Issues

### Issue: "Connection to database failed"

**Solution:** Make sure PostgreSQL is running and credentials match your `.env` file.

```bash
# Check if PostgreSQL is running
docker ps  # for Docker
brew services list  # for Homebrew
```

### Issue: "Migration already prepared"

**Solution:** If you need to reset migrations:

```bash
swift run NaturallyYoursServer migrate --revert
swift run NaturallyYoursServer migrate
```

### Issue: "Port 8080 already in use"

**Solution:** Either stop the process using port 8080, or change the port:

```bash
swift run NaturallyYoursServer serve --port 8081
```

## Project Structure

```
NaturallyYoursServer/
├── Models/
│   ├── User.swift          # Customer user model
│   ├── Admin.swift         # Admin user model
│   └── Todo.swift          # Example model (can delete)
├── DTOs/
│   └── AuthDTOs.swift      # Request/response structures
├── Controllers/
│   ├── UserAuthController.swift    # User authentication
│   ├── AdminAuthController.swift   # Admin authentication
│   └── ProductController.swift     # Example admin routes
├── Migrations/
│   ├── CreateUser.swift
│   ├── CreateAdmin.swift
│   └── CreateDefaultSuperAdmin.swift
├── Routes/
│   └── AuthRoutes.swift    # Route configuration
├── configure.swift         # App configuration
├── routes.swift           # Main routes file
└── entrypoint.swift       # App entry point
```

## Next Steps

Now that your authentication is working, you can:

1. **Add Product Models** - Create models for your beauty products
2. **Implement Shopping Cart** - Build cart functionality for users
3. **Add Order Processing** - Create order management system
4. **Integrate Payment** - Add Stripe or other payment providers
5. **Add OAuth** - Implement Sign in with Apple, Google, Facebook
6. **Email Notifications** - Send order confirmations and updates
7. **File Uploads** - Allow admins to upload product images
8. **Build iOS/iPadOS App** - Connect your mobile app to this backend

## Testing with iOS App

When connecting your iOS app:

1. Use `http://localhost:8080` when testing with Simulator
2. Use your Mac's local IP (e.g., `http://192.168.1.x:8080`) when testing on physical device
3. In production, deploy to a cloud service and use HTTPS

Example iOS connection:

```swift
let baseURL = "http://localhost:8080"

struct LoginRequest: Codable {
    let email: String
    let password: String
}

func login(email: String, password: String) async throws -> AuthResponse {
    let url = URL(string: "\(baseURL)/api/auth/users/login")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let credentials = "\(email):\(password)".data(using: .utf8)!.base64EncodedString()
    request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(AuthResponse.self, from: data)
}
```

## Security Reminders

- ✅ Change the default admin password immediately
- ✅ Use HTTPS in production
- ✅ Set secure session cookies in production
- ✅ Never commit `.env` files to version control
- ✅ Use strong passwords with required complexity
- ✅ Implement rate limiting for login attempts
- ✅ Add email verification before activation
- ✅ Enable two-factor authentication for admins

## Getting Help

- Check the [API Documentation](API_DOCUMENTATION.md) for endpoint details
- Review Vapor documentation: https://docs.vapor.codes
- Check your server logs for detailed error messages

Happy coding! 🚀
