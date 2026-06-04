# Admin Quick Reference Guide

Quick reference for common admin operations in your e-commerce system.

---

## 🔐 Admin Access Levels

| Role | Create Products | Edit Products | Delete Products | Manage Admins |
|------|----------------|---------------|-----------------|---------------|
| **Super Admin** | ✅ | ✅ | ✅ | ✅ |
| **Moderator** | ✅ | ✅ | ✅ | ❌ |
| **Support** | ❌ | ❌ | ❌ | ❌ |

---

## 📦 Product Management

### Create a New Product

**Endpoint:** `POST /api/products`

**Request:**
```json
{
  "name": "Shea Butter Moisturizer",
  "description": "Rich, natural moisturizer for all skin types",
  "price": 29.99,
  "salePrice": 24.99,
  "category": "Skin Care",
  "stockQuantity": 100,
  "imageURLs": [
    "https://yourcdn.com/shea-butter-1.jpg",
    "https://yourcdn.com/shea-butter-2.jpg"
  ],
  "sku": "SHEA-001",
  "weight": 6.0,
  "tags": ["moisturizer", "natural", "vegan"]
}
```

---

### Update Product Price

**Endpoint:** `PATCH /api/products/{productID}/price`

**Request:**
```json
{
  "price": 32.99,
  "salePrice": 27.99
}
```

**Remove Sale Price:**
```json
{
  "price": 29.99,
  "salePrice": null
}
```

---

### Update Stock Quantity

**Endpoint:** `PATCH /api/products/{productID}/stock`

**Request:**
```json
{
  "stockQuantity": 75
}
```

---

### Update Product Images

**Endpoint:** `PATCH /api/products/{productID}/images`

**Request:**
```json
{
  "imageURLs": [
    "https://yourcdn.com/new-image-1.jpg",
    "https://yourcdn.com/new-image-2.jpg",
    "https://yourcdn.com/new-image-3.jpg"
  ]
}
```

---

### Activate/Deactivate Product

**Show product to customers:**
```
POST /api/products/{productID}/activate
```

**Hide product from customers:**
```
POST /api/products/{productID}/deactivate
```

> **Note:** Deactivated products won't appear in public listings but remain in the database.

---

### Delete Product

**Endpoint:** `DELETE /api/products/{productID}`

> **Important:** If the product is in any customer's cart, it will be deactivated instead of deleted to prevent broken cart references.

---

### Update All Product Details

**Endpoint:** `PATCH /api/products/{productID}`

**Request (all fields optional):**
```json
{
  "name": "Updated Name",
  "description": "Updated description",
  "price": 35.99,
  "salePrice": 29.99,
  "category": "New Category",
  "stockQuantity": 50,
  "isActive": true,
  "imageURLs": ["new-urls..."],
  "sku": "NEW-SKU",
  "weight": 8.0,
  "tags": ["new", "tags"]
}
```

---

## 🔍 Finding Products

### Get All Products (Admin View)
```
GET /api/products?page=1&per=20
```
Shows all products including inactive ones (when logged in as admin).

### Search Products
```
GET /api/products/search?q=coconut
```

### Get Products by Category
```
GET /api/products/category/Hair%20Care
```

---

## 📊 Common Admin Workflows

### 1. Adding a New Product Line

```bash
# Step 1: Create the product
POST /api/products
{
  "name": "Coconut Hair Mask",
  "description": "Deep conditioning treatment",
  "price": 34.99,
  "category": "Hair Care",
  "stockQuantity": 50,
  "imageURLs": ["url1", "url2"],
  "tags": ["hair", "treatment", "coconut"]
}

# Step 2: Verify it's active (check response)
# isActive should be true by default

# Step 3: If needed, update images
PATCH /api/products/{id}/images
{
  "imageURLs": ["better-url1", "better-url2"]
}
```

---

### 2. Running a Sale

```bash
# Set sale prices for multiple products
PATCH /api/products/{productID}/price
{
  "salePrice": 19.99
}

# When sale ends, remove sale price
PATCH /api/products/{productID}/price
{
  "salePrice": null
}
```

---

### 3. Managing Low Stock

```bash
# Check stock levels (query your database or add custom endpoint)
GET /api/products

# Update stock when shipment arrives
PATCH /api/products/{productID}/stock
{
  "stockQuantity": 150
}
```

---

### 4. Seasonal Product Management

```bash
# Hide seasonal products
POST /api/products/{productID}/deactivate

# When season returns
POST /api/products/{productID}/activate
```

---

## 🛡️ Security Best Practices

### Always Verify Admin Status
Before making admin calls, ensure:
1. Admin is logged in (session cookie is present)
2. Admin has correct role (Moderator or Super Admin)
3. Session hasn't expired

### Example Request Headers
```
Cookie: vapor_session=abc123...
Content-Type: application/json
```

---

## ⚠️ Common Issues & Solutions

### Issue: "Insufficient permissions"
**Solution:** Check admin role. Only Moderator and Super Admin can manage products.

### Issue: "Product not found"
**Solution:** Verify the product ID is correct and product exists in database.

### Issue: "Not enough stock available"
**Solution:** Customer tried to add more items than available. Update stock quantity or notify customer.

### Issue: Can't delete product
**Solution:** Product is in active carts. It will be deactivated instead. This is by design to prevent broken cart references.

---

## 📱 Recommended Admin Dashboard Features

### Product Management Screen
```
┌────────────────────────────────────────┐
│  Products                    [+ New]   │
├────────────────────────────────────────┤
│                                        │
│  🖼️ Coconut Hair Oil                   │
│     $24.99  Sale: $19.99              │
│     Stock: 50  Active: ✅              │
│     [Edit] [Deactivate] [Delete]      │
│                                        │
│  🖼️ Shea Butter Cream                  │
│     $29.99                             │
│     Stock: 25  Active: ✅              │
│     [Edit] [Deactivate] [Delete]      │
│                                        │
└────────────────────────────────────────┘
```

### Quick Actions Menu
- ⚡ Add New Product
- 💰 Bulk Price Update
- 📦 Update Stock Levels
- 🏷️ Manage Categories
- 📊 View Sales Reports (future feature)

---

## 🎯 Performance Tips

1. **Batch Operations**: When updating multiple products, do it in parallel:
```swift
await withTaskGroup(of: Void.self) { group in
    for productID in productIDs {
        group.addTask {
            try await updateProduct(id: productID)
        }
    }
}
```

2. **Image Optimization**: 
   - Use compressed images (WebP format recommended)
   - Resize images before upload (max 1200px width)
   - Use a CDN for image hosting

3. **Caching**: Consider caching product lists for better performance

---

## 📋 Pre-Launch Checklist

Before going live, ensure:
- [ ] All products have high-quality images
- [ ] All products have accurate descriptions
- [ ] All prices are correct
- [ ] Stock quantities are accurate
- [ ] Product categories are consistent
- [ ] Test cart functionality with real products
- [ ] Verify admin permissions work correctly
- [ ] Test product search
- [ ] Check mobile responsiveness

---

## 🚀 Advanced Features (Coming Soon)

Consider implementing:
- **Product Reviews**: Customer ratings and reviews
- **Product Variants**: Size, color, scent options
- **Bulk Import**: CSV upload for products
- **Analytics Dashboard**: Sales tracking, popular products
- **Inventory Alerts**: Low stock notifications
- **Product Recommendations**: "Customers also bought..."
- **Discount Codes**: Promo codes and coupons

---

## 📞 Support

For technical issues:
1. Check the main API documentation (`E_COMMERCE_API.md`)
2. Review the implementation guide (`ECOMMERCE_IMPLEMENTATION.md`)
3. Check Vapor server logs for error details
4. Verify database migrations ran successfully

---

## 🎓 Tips for Training Staff

When onboarding new admin users:
1. Start with viewing products only
2. Practice creating test products
3. Learn to update prices and stock
4. Understand when to deactivate vs delete
5. Use staging environment for training
6. Create admin training documentation specific to your workflow

---

**Remember:** With great admin power comes great responsibility! Always double-check changes before saving, especially price updates. 🛡️
