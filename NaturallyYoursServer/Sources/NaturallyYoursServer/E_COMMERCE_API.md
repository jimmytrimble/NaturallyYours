# E-Commerce API Documentation

## Overview
This document provides comprehensive API documentation for the e-commerce features including product management, shopping cart, and favorites/wishlist functionality.

---

## Table of Contents
1. [Product Management](#product-management)
2. [Shopping Cart](#shopping-cart)
3. [Favorites/Wishlist](#favoriteswishlist)

---

## Product Management

### Public Routes (No Authentication Required)

#### 1. List All Products
**GET** `/api/products`

Get a paginated list of all active products.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per` (optional): Items per page (default: 20)

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "uuid",
      "name": "Coconut Hair Oil",
      "description": "Natural coconut oil for healthy hair",
      "price": 24.99,
      "salePrice": 19.99,
      "effectivePrice": 19.99,
      "category": "Hair Care",
      "stockQuantity": 50,
      "inStock": true,
      "onSale": true,
      "isActive": true,
      "imageURLs": [
        "https://example.com/product1.jpg",
        "https://example.com/product1-alt.jpg"
      ],
      "sku": "COCO-001",
      "weight": 8.5,
      "tags": ["organic", "vegan", "hair"],
      "createdAt": "2026-05-28T10:00:00Z",
      "updatedAt": "2026-05-28T12:00:00Z"
    }
  ],
  "metadata": {
    "page": 1,
    "per": 20,
    "total": 45
  }
}
```

---

#### 2. Get Single Product
**GET** `/api/products/:productID`

Get details of a specific product.

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Coconut Hair Oil",
  "description": "Natural coconut oil for healthy hair",
  "price": 24.99,
  "salePrice": 19.99,
  "effectivePrice": 19.99,
  "category": "Hair Care",
  "stockQuantity": 50,
  "inStock": true,
  "onSale": true,
  "isActive": true,
  "imageURLs": ["https://example.com/product1.jpg"],
  "sku": "COCO-001",
  "weight": 8.5,
  "tags": ["organic", "vegan", "hair"],
  "createdAt": "2026-05-28T10:00:00Z",
  "updatedAt": "2026-05-28T12:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid product ID
- `404 Not Found`: Product not found

---

#### 3. Get Products by Category
**GET** `/api/products/category/:category`

Get all products in a specific category.

**Response (200 OK):**
```json
[
  {
    "id": "uuid",
    "name": "Coconut Hair Oil",
    "price": 24.99,
    ...
  }
]
```

---

#### 4. Search Products
**GET** `/api/products/search?q=coconut`

Search products by name or description.

**Query Parameters:**
- `q` (required): Search query

**Response (200 OK):**
```json
[
  {
    "id": "uuid",
    "name": "Coconut Hair Oil",
    "price": 24.99,
    ...
  }
]
```

---

### Admin Routes (Requires Moderator or Super Admin)

#### 5. Create Product
**POST** `/api/products`

Create a new product. Requires admin authentication with moderator or super admin role.

**Request Body:**
```json
{
  "name": "Coconut Hair Oil",
  "description": "Natural coconut oil for healthy hair",
  "price": 24.99,
  "salePrice": 19.99,
  "category": "Hair Care",
  "stockQuantity": 50,
  "imageURLs": [
    "https://example.com/product1.jpg"
  ],
  "sku": "COCO-001",
  "weight": 8.5,
  "tags": ["organic", "vegan", "hair"]
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "name": "Coconut Hair Oil",
  "description": "Natural coconut oil for healthy hair",
  ...
}
```

**Error Responses:**
- `400 Bad Request`: Validation failed
- `401 Unauthorized`: Not authenticated
- `403 Forbidden`: Insufficient permissions

---

#### 6. Update Product
**PATCH** `/api/products/:productID`

Update an existing product. All fields are optional.

**Request Body:**
```json
{
  "name": "Updated Coconut Hair Oil",
  "price": 29.99,
  "stockQuantity": 75,
  "isActive": true
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Updated Coconut Hair Oil",
  ...
}
```

---

#### 7. Delete Product
**DELETE** `/api/products/:productID`

Delete a product. If the product is in any active carts, it will be deactivated instead of deleted.

**Response (204 No Content)** or **(200 OK)** if deactivated

**Error Responses:**
- `404 Not Found`: Product not found

---

#### 8. Update Product Price
**PATCH** `/api/products/:productID/price`

Update product pricing.

**Request Body:**
```json
{
  "price": 29.99,
  "salePrice": 24.99
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "price": 29.99,
  "salePrice": 24.99,
  ...
}
```

---

#### 9. Update Product Stock
**PATCH** `/api/products/:productID/stock`

Update product stock quantity.

**Request Body:**
```json
{
  "stockQuantity": 100
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "stockQuantity": 100,
  ...
}
```

---

#### 10. Update Product Images
**PATCH** `/api/products/:productID/images`

Update product image URLs.

**Request Body:**
```json
{
  "imageURLs": [
    "https://example.com/new-image1.jpg",
    "https://example.com/new-image2.jpg"
  ]
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "imageURLs": ["https://example.com/new-image1.jpg", ...],
  ...
}
```

---

#### 11. Activate Product
**POST** `/api/products/:productID/activate`

Make a product visible to customers.

**Response (200 OK):**
```json
{
  "id": "uuid",
  "isActive": true,
  ...
}
```

---

#### 12. Deactivate Product
**POST** `/api/products/:productID/deactivate`

Hide a product from customers without deleting it.

**Response (200 OK):**
```json
{
  "id": "uuid",
  "isActive": false,
  ...
}
```

---

## Shopping Cart

All cart operations work for both authenticated users and guests. Guest carts are tracked via session cookies.

### Cart Routes

#### 1. Get Cart
**GET** `/api/cart`

Get the current user's or guest's cart with all items.

**Response (200 OK):**
```json
{
  "id": "uuid",
  "items": [
    {
      "id": "uuid",
      "product": {
        "id": "uuid",
        "name": "Coconut Hair Oil",
        "price": 24.99,
        ...
      },
      "quantity": 2,
      "priceAtAddition": 19.99,
      "lineTotal": 39.98
    }
  ],
  "subtotal": 39.98,
  "itemCount": 2,
  "isActive": true,
  "createdAt": "2026-05-28T10:00:00Z"
}
```

---

#### 2. Add to Cart
**POST** `/api/cart/items`

Add a product to the cart or increase quantity if already present.

**Request Body:**
```json
{
  "productID": "uuid",
  "quantity": 2
}
```

**Response (200 OK):**
Returns the updated cart (same format as Get Cart).

**Error Responses:**
- `400 Bad Request`: Invalid data or not enough stock
- `404 Not Found`: Product not found

---

#### 3. Update Cart Item Quantity
**PATCH** `/api/cart/items/:cartItemID`

Update the quantity of a cart item. Set quantity to 0 to remove the item.

**Request Body:**
```json
{
  "quantity": 3
}
```

**Response (200 OK):**
Returns the updated cart.

**Error Responses:**
- `400 Bad Request`: Not enough stock
- `403 Forbidden`: Cart item doesn't belong to you
- `404 Not Found`: Cart item not found

---

#### 4. Remove Item from Cart
**DELETE** `/api/cart/items/:cartItemID`

Remove a specific item from the cart.

**Response (204 No Content)**

**Error Responses:**
- `403 Forbidden`: Cart item doesn't belong to you
- `404 Not Found`: Cart item not found

---

#### 5. Clear Cart
**DELETE** `/api/cart/clear`

Remove all items from the cart.

**Response (204 No Content)**

---

### Authenticated User Only

#### 6. Merge Guest Cart
**POST** `/api/cart/merge`

Merge a guest cart into the user's cart upon login. This is typically called automatically by your frontend after successful login.

**Request Body:**
```json
{
  "guestSessionID": "uuid-string"
}
```

**Response (200 OK):**
Returns the merged cart.

---

## Favorites/Wishlist

All favorites routes require user authentication. Guests cannot save favorites.

### Favorites Routes

#### 1. List Favorites
**GET** `/api/favorites`

Get all products in the user's favorites list.

**Response (200 OK):**
```json
{
  "favorites": [
    {
      "id": "uuid",
      "product": {
        "id": "uuid",
        "name": "Coconut Hair Oil",
        "price": 24.99,
        ...
      },
      "createdAt": "2026-05-28T10:00:00Z"
    }
  ],
  "count": 5
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated

---

#### 2. Add to Favorites
**POST** `/api/favorites`

Add a product to the user's favorites.

**Request Body:**
```json
{
  "productID": "uuid"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "product": {
    "id": "uuid",
    "name": "Coconut Hair Oil",
    ...
  },
  "createdAt": "2026-05-28T10:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `404 Not Found`: Product not found
- `409 Conflict`: Product already in favorites

---

#### 3. Remove from Favorites
**DELETE** `/api/favorites/:favoriteID`

Remove a product from favorites using the favorite ID.

**Response (204 No Content)**

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `404 Not Found`: Favorite not found

---

#### 4. Remove from Favorites by Product
**DELETE** `/api/favorites/product/:productID`

Remove a product from favorites using the product ID (convenience method).

**Response (204 No Content)**

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `404 Not Found`: Product not in favorites

---

#### 5. Check if Product is Favorited
**GET** `/api/favorites/check/:productID`

Check if a specific product is in the user's favorites.

**Response (200 OK):**
```json
{
  "isFavorite": true,
  "favoriteID": "uuid"
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated

---

## Common Error Responses

All endpoints may return the following errors:

- `401 Unauthorized`: Authentication required or invalid
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation failed
- `500 Internal Server Error`: Server error

Error response format:
```json
{
  "error": true,
  "reason": "Detailed error message"
}
```

---

## Authentication

### Admin Routes
Admin routes require session-based authentication. Include the session cookie in all requests:
```
Cookie: vapor_session=<session-token>
```

### User Routes (Cart Merge, Favorites)
User routes also use session-based authentication with the same cookie format.

### Guest Routes (Cart)
Guest cart functionality automatically creates and maintains a session. Make sure to persist cookies across requests.

---

## Rate Limiting

Consider implementing rate limiting on your production server to prevent abuse, especially on:
- Cart operations (prevent cart stuffing)
- Favorites operations (prevent spam)
- Search endpoints (prevent scraping)

---

## Best Practices

### Frontend Integration

1. **Cart Management for Guests:**
   - Maintain cart state using session cookies
   - When user logs in, call the merge endpoint to combine guest cart with user cart

2. **Product Images:**
   - Always display the first image from `imageURLs` array as the primary image
   - Use additional images for gallery views

3. **Stock Checking:**
   - Before checkout, verify all items are still in stock
   - Display stock availability to users

4. **Price Consistency:**
   - Cart items store `priceAtAddition` to ensure price consistency
   - Display original price if it differs from current price

5. **Favorites:**
   - Show heart icon on product cards
   - Use the "Check if Product is Favorited" endpoint to determine state
   - Prompt guests to sign up when they try to add favorites

---

## Database Considerations

### Indexes
The following indexes are recommended for optimal performance:

```sql
-- Products
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_name ON products(name);

-- Carts
CREATE INDEX idx_carts_user_id ON carts(user_id);
CREATE INDEX idx_carts_session_id ON carts(session_id);
CREATE INDEX idx_carts_is_active ON carts(is_active);

-- Cart Items
CREATE INDEX idx_cart_items_cart_id ON cart_items(cart_id);
CREATE INDEX idx_cart_items_product_id ON cart_items(product_id);

-- Favorites
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_product_id ON favorites(product_id);
```

### Data Cleanup
Consider implementing scheduled tasks to:
- Delete expired guest carts (older than 30 days)
- Archive inactive carts (no activity for 90 days)
- Clean up orphaned cart items

---

## Testing

### Example Test Scenarios

1. **Product Management:**
   - Create product with all fields
   - Update product fields individually
   - Delete product with/without cart items
   - Search and filter products

2. **Cart Operations:**
   - Add items as guest
   - Add items as authenticated user
   - Update quantities
   - Handle out-of-stock scenarios
   - Merge guest cart into user cart

3. **Favorites:**
   - Add/remove favorites
   - Handle duplicate favorites
   - Check favorite status

---

## Migration Order

When deploying, ensure migrations run in this order:
1. CreateUser
2. CreateAdmin
3. CreateProduct
4. CreateCart
5. CreateCartItem
6. CreateFavorite

This order ensures foreign key relationships are properly established.
