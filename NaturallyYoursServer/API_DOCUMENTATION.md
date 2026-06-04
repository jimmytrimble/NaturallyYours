# Naturally Yours Server - Authentication API

This backend server provides authentication and authorization for the Naturally Yours e-commerce app, which sells beauty products.

## Features

- **User Authentication**: Email/password signup and login for customers
- **Guest Checkout**: Allow users to purchase without creating an account
- **Admin Authentication**: Separate login for administrators with role-based permissions
- **Session Management**: Secure session-based authentication
- **Password Security**: Bcrypt hashing with strict password requirements

## Getting Started

### Prerequisites

- Swift 6.0+
- PostgreSQL database
- Vapor 4.115.0+

### Environment Variables

Create a `.env` file in the root directory:

```env
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=vapor_username
DATABASE_PASSWORD=vapor_password
DATABASE_NAME=vapor_database
```

### Running Migrations

```bash
swift run NaturallyYoursServer migrate
```

### Starting the Server

```bash
swift run NaturallyYoursServer serve
```

## API Endpoints

### User Authentication

#### 1. Sign Up (POST `/api/auth/users/signup`)

Create a new customer account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "confirmPassword": "SecurePass123"
}
```

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2026-05-28T10:00:00Z"
  },
  "token": null
}
```

**Error Responses:**
- `400 Bad Request`: Validation failed or passwords don't match
- `409 Conflict`: User with this email already exists

---

#### 2. Log In (POST `/api/auth/users/login`)

Authenticate an existing user.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2026-05-28T10:00:00Z"
  },
  "token": null
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid credentials

---

#### 3. Log Out (POST `/api/auth/users/logout`)

Log out the current user.

**Headers:**
- Requires authenticated session cookie

**Response:**
- `204 No Content`

---

#### 4. Get Current User (GET `/api/auth/users/me`)

Get the currently authenticated user's information.

**Headers:**
- Requires authenticated session cookie

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "createdAt": "2026-05-28T10:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized`: Not authenticated

---

### Guest Checkout

#### 5. Guest Checkout (POST `/api/guest/checkout`)

Allow users to complete a purchase without creating an account.

**Request Body:**
```json
{
  "email": "guest@example.com",
  "name": "Guest User"
}
```

**Response (200 OK):**
```json
{
  "orderId": "uuid",
  "email": "guest@example.com",
  "message": "Order placed successfully. A confirmation email has been sent."
}
```

---

### Admin Authentication

#### 6. Admin Log In (POST `/api/auth/admins/login`)

Authenticate as an administrator.

**Request Body:**
```json
{
  "email": "admin@naturallyyours.com",
  "password": "AdminPass123"
}
```

**Response (200 OK):**
```json
{
  "admin": {
    "id": "uuid",
    "name": "Admin User",
    "email": "admin@naturallyyours.com",
    "role": "super_admin",
    "createdAt": "2026-05-28T10:00:00Z"
  },
  "token": null
}
```

---

#### 7. Admin Log Out (POST `/api/auth/admins/logout`)

Log out the current admin.

**Headers:**
- Requires authenticated admin session cookie

**Response:**
- `204 No Content`

---

#### 8. Get Current Admin (GET `/api/auth/admins/me`)

Get the currently authenticated admin's information.

**Headers:**
- Requires authenticated admin session cookie

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Admin User",
  "email": "admin@naturallyyours.com",
  "role": "super_admin",
  "createdAt": "2026-05-28T10:00:00Z"
}
```

---

#### 9. Create Admin (POST `/api/auth/admins/create`)

Create a new admin account. **Super Admin only**.

**Headers:**
- Requires authenticated super admin session cookie

**Request Body:**
```json
{
  "name": "New Admin",
  "email": "newadmin@naturallyyours.com",
  "password": "AdminPass123",
  "confirmPassword": "AdminPass123",
  "role": "moderator"
}
```

**Admin Roles:**
- `super_admin`: Full access to everything (can create/delete admins)
- `moderator`: Can edit products, prices, and layout
- `support`: Read-only access for customer support

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "New Admin",
  "email": "newadmin@naturallyyours.com",
  "role": "moderator",
  "createdAt": "2026-05-28T10:00:00Z"
}
```

---

#### 10. List Admins (GET `/api/auth/admins/list`)

Get a list of all admins. **Super Admin only**.

**Headers:**
- Requires authenticated super admin session cookie

**Response (200 OK):**
```json
[
  {
    "id": "uuid",
    "name": "Admin User",
    "email": "admin@naturallyyours.com",
    "role": "super_admin",
    "createdAt": "2026-05-28T10:00:00Z"
  },
  {
    "id": "uuid",
    "name": "Moderator User",
    "email": "mod@naturallyyours.com",
    "role": "moderator",
    "createdAt": "2026-05-28T10:00:00Z"
  }
]
```

---

#### 11. Delete Admin (DELETE `/api/auth/admins/:adminID`)

Delete an admin account. **Super Admin only**.

**Headers:**
- Requires authenticated super admin session cookie

**Parameters:**
- `adminID`: UUID of the admin to delete

**Response:**
- `204 No Content`

**Error Responses:**
- `400 Bad Request`: Cannot delete your own account
- `404 Not Found`: Admin not found

---

## Admin Role Permissions

| Action | Super Admin | Moderator | Support |
|--------|-------------|-----------|---------|
| Create/Delete Admins | ✅ | ❌ | ❌ |
| Edit Products | ✅ | ✅ | ❌ |
| Edit Prices | ✅ | ✅ | ❌ |
| Edit Layout | ✅ | ✅ | ❌ |
| View Customer Data | ✅ | ✅ | ✅ |

## Security Considerations

1. **Password Hashing**: All passwords are hashed using Bcrypt before storage
2. **Session Management**: Sessions are stored in the database using Fluent
3. **Unique Emails**: Email addresses must be unique for both users and admins
4. **Admin Separation**: Admin and user authentication are completely separate systems
5. **Role-Based Access**: Admin routes are protected by role-specific middleware

## Creating Your First Super Admin

Since only super admins can create other admins, you'll need to manually create the first one:

```swift
// Add this to a migration or run it once in your code
let passwordHash = try Bcrypt.hash("YourSecurePassword123")
let superAdmin = Admin(
    name: "Super Admin",
    email: "superadmin@naturallyyours.com",
    passwordHash: passwordHash,
    role: .superAdmin
)
try await superAdmin.save(on: db)
```

Or create a migration file for this purpose.

## Next Steps

1. **Add Product Models**: Create models for products, categories, and inventory
2. **Implement Cart System**: Build shopping cart functionality
3. **Add Order Management**: Create order processing and tracking
4. **Integrate Payment**: Add Stripe or other payment processing
5. **OAuth Integration**: Implement Sign in with Apple, Google, and Facebook
6. **Email Service**: Add email verification and order confirmations
7. **File Upload**: Allow admins to upload product images
8. **Search & Filtering**: Add product search capabilities

## Testing with cURL

### Sign up a new user:
```bash
curl -X POST http://localhost:8080/api/auth/users/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "SecurePass123",
    "confirmPassword": "SecurePass123"
  }' \
  -c cookies.txt
```

### Log in:
```bash
curl -X POST http://localhost:8080/api/auth/users/login \
  -H "Content-Type: application/json" \
  -u "test@example.com:SecurePass123" \
  -c cookies.txt
```

### Get current user (using session cookie):
```bash
curl -X GET http://localhost:8080/api/auth/users/me \
  -b cookies.txt
```

## License

MIT
