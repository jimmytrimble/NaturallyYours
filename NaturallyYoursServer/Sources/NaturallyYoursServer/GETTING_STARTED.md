# Getting Started with Your E-Commerce Backend

Welcome! This guide will help you get your e-commerce backend up and running in minutes.

---

## 🚀 Quick Start

### 1. Run Migrations
First, make sure all database tables are created:

```bash
swift build
swift run NaturallyYoursServer migrate --yes
```

### 2. Create Your First Admin
You should have already set up a super admin. If not, uncomment the line in `configure.swift`:

```swift
app.migrations.add(CreateDefaultSuperAdmin())
```

Then run migrations again.

### 3. Seed Sample Products
Populate your database with sample beauty products:

```bash
swift run NaturallyYoursServer seed:products
```

To clear existing products and start fresh:
```bash
swift run NaturallyYoursServer seed:products --clear
```

### 4. Start the Server
```bash
swift run NaturallyYoursServer serve
```

Your server will be running at `http://localhost:8080`

---

## 🧪 Test Your Setup

### Test 1: View Products (No Auth Required)
```bash
curl http://localhost:8080/api/products
```

You should see a list of products with their details.

### Test 2: Login as Admin
```bash
curl -X POST http://localhost:8080/api/auth/admins/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "super@naturally.com",
    "password": "SuperSecure123"
  }' \
  -c cookies.txt
```

Save the session cookie for subsequent requests.

### Test 3: Create a Product (Admin Only)
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "name": "My First Product",
    "description": "This is a test product",
    "price": 19.99,
    "category": "Test",
    "stockQuantity": 10,
    "imageURLs": ["https://via.placeholder.com/400"],
    "tags": ["test"]
  }'
```

### Test 4: Add to Cart (Guest)
```bash
# Get a product ID from the products list
PRODUCT_ID="paste-product-id-here"

curl -X POST http://localhost:8080/api/cart/items \
  -H "Content-Type: application/json" \
  -c cart-cookies.txt \
  -d "{
    \"productID\": \"$PRODUCT_ID\",
    \"quantity\": 2
  }"
```

### Test 5: View Cart
```bash
curl http://localhost:8080/api/cart \
  -b cart-cookies.txt
```

---

## 📱 Frontend Integration

### Swift Example (iOS/macOS)

#### 1. Fetch Products
```swift
func fetchProducts() async throws -> [ProductDTO] {
    let url = URL(string: "http://localhost:8080/api/products")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(Page<ProductDTO>.self, from: data)
    return response.items
}
```

#### 2. Add to Cart
```swift
func addToCart(productID: UUID, quantity: Int) async throws {
    let url = URL(string: "http://localhost:8080/api/cart/items")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["productID": productID.uuidString, "quantity": quantity]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (_, _) = try await URLSession.shared.data(for: request)
}
```

#### 3. Admin: Create Product
```swift
func createProduct(
    name: String,
    description: String,
    price: Double,
    category: String,
    stockQuantity: Int
) async throws -> ProductDTO {
    let url = URL(string: "http://localhost:8080/api/products")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    // Include session cookie for authentication
    
    let body = CreateProductRequest(
        name: name,
        description: description,
        price: price,
        salePrice: nil,
        category: category,
        stockQuantity: stockQuantity,
        imageURLs: [],
        sku: nil,
        weight: nil,
        tags: []
    )
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(ProductDTO.self, from: data)
}
```

---

## 🗂️ Project Structure

```
NaturallyYoursServer/
├── configure.swift              # App configuration
├── routes.swift                 # Route registration
│
├── Models/
│   ├── ModelsUser.swift        # Customer model
│   ├── ModelsAdmin.swift       # Admin model
│   ├── ModelsProduct.swift     # Product model
│   ├── ModelsCart.swift        # Cart & CartItem models
│   └── ModelsFavorite.swift    # Favorites model
│
├── Controllers/
│   ├── ControllersUserAuthController.swift
│   ├── ControllersAdminAuthController.swift
│   ├── ControllersProductManagementController.swift
│   ├── ControllersCartController.swift
│   └── ControllersFavoritesController.swift
│
├── Migrations/
│   ├── MigrationsCreateUser.swift
│   ├── MigrationsCreateAdmin.swift
│   ├── MigrationsCreateProduct.swift
│   ├── MigrationsCreateCart.swift
│   └── MigrationsCreateFavorite.swift
│
├── Middleware/
│   └── MiddlewareAdminMiddleware.swift
│
├── Commands/
│   └── CommandsSeedProductsCommand.swift
│
└── Documentation/
    ├── E_COMMERCE_API.md
    ├── ECOMMERCE_IMPLEMENTATION.md
    └── ADMIN_QUICK_REFERENCE.md
```

---

## 🎯 Common Use Cases

### For Customers

#### Browse Products
```
GET /api/products
GET /api/products/category/Hair%20Care
GET /api/products/search?q=coconut
```

#### Shopping Cart
```
GET /api/cart                        # View cart
POST /api/cart/items                 # Add to cart
PATCH /api/cart/items/:id            # Update quantity
DELETE /api/cart/items/:id           # Remove item
DELETE /api/cart/clear               # Clear cart
```

#### Favorites (Requires Login)
```
GET /api/favorites                   # List favorites
POST /api/favorites                  # Add favorite
DELETE /api/favorites/:id            # Remove favorite
GET /api/favorites/check/:productID  # Check if favorited
```

---

### For Admins

#### Product Management
```
POST /api/products                     # Create product
PATCH /api/products/:id                # Update product
DELETE /api/products/:id               # Delete product
PATCH /api/products/:id/price          # Update price
PATCH /api/products/:id/stock          # Update stock
PATCH /api/products/:id/images         # Update images
POST /api/products/:id/activate        # Activate product
POST /api/products/:id/deactivate      # Deactivate product
```

---

## 💡 Pro Tips

### 1. Image Hosting
For production, use a CDN or cloud storage:
- **AWS S3**: Scalable, reliable
- **Cloudflare Images**: Fast, optimized
- **Cloudinary**: Image transformations
- **imgix**: Advanced processing

Example workflow:
```swift
// 1. Upload image to S3
let imageURL = try await uploadToS3(image)

// 2. Create product with image URL
let product = try await createProduct(
    name: "Product",
    imageURLs: [imageURL],
    ...
)
```

### 2. Session Management
Sessions expire after inactivity. Refresh them:
```swift
// Periodically check if session is valid
func keepSessionAlive() async {
    try? await URLSession.shared.data(from: URL(string: "http://localhost:8080/api/auth/users/me")!)
}
```

### 3. Cart Persistence
Guest carts persist for 30 days. Merge on login:
```swift
// After successful login
func mergeGuestCart(guestSessionID: String) async throws {
    let url = URL(string: "http://localhost:8080/api/cart/merge")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let body = ["guestSessionID": guestSessionID]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (_, _) = try await URLSession.shared.data(for: request)
}
```

### 4. Stock Checking
Before checkout, verify stock:
```swift
func verifyStock() async throws -> Bool {
    let cart = try await getCart()
    
    for item in cart.items {
        let product = try await fetchProduct(id: item.product.id)
        
        if product.stockQuantity < item.quantity {
            // Not enough stock
            return false
        }
    }
    
    return true
}
```

---

## ⚙️ Configuration

### Database Configuration

#### Development (SQLite)
Already configured in `configure.swift`:
```swift
app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

#### Production (PostgreSQL)
Update `configure.swift`:
```swift
app.databases.use(.postgres(
    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
    username: Environment.get("DATABASE_USERNAME") ?? "vapor",
    password: Environment.get("DATABASE_PASSWORD") ?? "",
    database: Environment.get("DATABASE_NAME") ?? "vapor"
), as: .psql)
```

### Environment Variables
Create a `.env` file:
```env
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=vapor
DATABASE_PASSWORD=yourpassword
DATABASE_NAME=naturally_yours
```

---

## 🔒 Security Checklist

Before production:
- [ ] Switch from SQLite to PostgreSQL
- [ ] Remove or comment out `app.autoMigrate()`
- [ ] Use HTTPS only
- [ ] Set secure cookie flags
- [ ] Implement rate limiting
- [ ] Add CORS middleware if needed
- [ ] Review admin permissions
- [ ] Secure image uploads
- [ ] Add input sanitization
- [ ] Enable logging and monitoring

---

## 🐛 Troubleshooting

### Issue: "Migration failed"
**Solution:** 
```bash
# Check which migrations have run
swift run NaturallyYoursServer migrate --check

# Revert and try again
swift run NaturallyYoursServer migrate --revert
swift run NaturallyYoursServer migrate --yes
```

### Issue: "Unauthorized" on admin routes
**Solution:**
1. Verify you're logged in as admin
2. Check session cookie is being sent
3. Verify admin has correct role (Moderator or Super Admin)

### Issue: "Product not found"
**Solution:**
1. Run the seed command: `swift run NaturallyYoursServer seed:products`
2. Check database: `sqlite3 db.sqlite "SELECT * FROM products;"`

### Issue: Cart not persisting
**Solution:**
1. Ensure cookies are enabled
2. Check session middleware is configured
3. Verify session storage is working

---

## 📚 Additional Resources

- **Main API Documentation**: `E_COMMERCE_API.md`
- **Implementation Guide**: `ECOMMERCE_IMPLEMENTATION.md`
- **Admin Guide**: `ADMIN_QUICK_REFERENCE.md`
- **System Architecture**: `ARCHITECTURE.md`
- **Vapor Documentation**: https://docs.vapor.codes

---

## 🎉 Next Steps

Now that your backend is running, you can:

1. **Build Your Frontend**
   - Create product listing screens
   - Implement cart UI
   - Add favorites/wishlist
   - Build admin dashboard

2. **Add More Features**
   - Order management
   - Payment integration (Stripe, PayPal)
   - Email notifications
   - Reviews and ratings
   - Discount codes

3. **Optimize Performance**
   - Add caching
   - Optimize database queries
   - Implement pagination
   - Add image optimization

4. **Deploy to Production**
   - Set up PostgreSQL
   - Configure environment variables
   - Set up CI/CD
   - Monitor and log

---

**Happy coding! 🚀** Your e-commerce backend is ready to power your Naturally Yours beauty products app!

For questions or issues, refer to the documentation files or check the Vapor community resources.
