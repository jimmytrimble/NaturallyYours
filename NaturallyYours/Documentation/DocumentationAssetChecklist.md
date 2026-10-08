# Asset Checklist for Naturally Yours App

## Required Assets for Home Screen

### 🎯 Priority 1: Essential Images

#### Hero Section
- [ ] `hero_image` - Main banner image (1200×600px, landscape)
  - Should showcase products or model
  - Match website hero aesthetic
  - JPEG format

#### Logo
- [ ] `naturally_yours_logo_white` - White version for dark backgrounds (optional)
- [ ] `naturally_yours_logo_black` - Black version for light backgrounds (optional)
  - Note: Currently using text, but you can replace with image if preferred

### 🛍️ Priority 2: Product Images

#### Featured Products (Minimum 4)
- [ ] `product1` - Featured product image (400×400px, square)
- [ ] `product2` - Featured product image (400×400px, square)
- [ ] `product3` - Featured product image (400×400px, square)
- [ ] `product4` - Featured product image (400×400px, square)
- [ ] `product5` - Featured product image (400×400px, square) - Optional
- [ ] `product6` - Featured product image (400×400px, square) - Optional

**Image Requirements:**
- Square format (1:1 ratio)
- White or transparent background
- Professional product photography
- PNG or JPEG format
- Show product packaging clearly

### 📦 Priority 3: Collection Images

- [ ] `collection_haircare` - Hair care category (600×500px, landscape)
- [ ] `collection_styling` - Styling products category (600×500px, landscape)
- [ ] `collection_treatments` - Treatment products category (600×500px, landscape)
- [ ] `collection_accessories` - Accessories category (600×500px, landscape)

**Image Requirements:**
- Landscape format (6:5 ratio)
- Can be lifestyle shots or product groupings
- JPEG format
- Should be visually distinct from each other

### 🏷️ Priority 4: Brand Logos

- [ ] `brand_ny` - Naturally Yours logo (300×300px, square)
- [ ] `brand_shea` - Shea Moisture logo (300×300px, square)
- [ ] `brand_cantu` - Cantu logo (300×300px, square)
- [ ] `brand_mielle` - Mielle logo (300×300px, square)

**Add your own brands:**
- [ ] `brand_____` - Additional brand (300×300px, square)
- [ ] `brand_____` - Additional brand (300×300px, square)

**Image Requirements:**
- Square format (1:1 ratio)
- PNG with transparent background preferred
- Clear, recognizable brand logo
- Include padding within image

### 💬 Priority 5: Testimonial Images (Optional but recommended)

- [ ] `testimonial1` - Customer photo (200×200px, square)
- [ ] `testimonial2` - Customer photo (200×200px, square)
- [ ] `testimonial3` - Customer photo (200×200px, square)

**Image Requirements:**
- Square format (1:1 ratio)
- Professional or high-quality photos
- PNG or JPEG format
- Faces should be clearly visible

**Note:** Testimonial images are optional. The app will show placeholder avatars if not provided.

## Font Assets

### Custom Font (Highly Recommended)
- [ ] Handwritten/script font file for "Naturally Yours" logo
  - `.ttf` or `.otf` format
  - Should match website logo style
  - Examples: Pacifico, Dancing Script, Great Vibes, or custom font

**If you have the exact font from your website logo, add it here!**

## How to Add Assets to Xcode

### For Images:

1. **Open your project in Xcode**
2. **Navigate to Assets.xcassets** (usually in the left sidebar)
3. **Create new image sets:**
   - Click the `+` button at the bottom
   - Select "Image Set"
   - Name it exactly as shown above (e.g., `product1`)
4. **Add your images:**
   - Drag your image files into the 1x, 2x, and 3x slots
   - Or just add to "Universal" if you only have one size
5. **Repeat** for all images

### For Fonts:

1. **Add font file to project:**
   - Drag the `.ttf` or `.otf` file into Xcode
   - Make sure "Copy items if needed" is checked
   - Select your app target
2. **Update Info.plist:**
   - Open `Info.plist`
   - Add a new row: "Fonts provided by application"
   - Add your font filename with extension
3. **Update code:**
   - Open `Extensions/Font+Theme.swift`
   - Replace the `nyLogoFont()` implementation with:
   ```swift
   return .custom("YourFontName", size: size)
   ```

## Image Size Quick Reference

| Asset Type | Dimensions | Aspect Ratio | Format |
|------------|------------|--------------|--------|
| Hero Image | 1200×600px | 2:1 | JPEG |
| Products | 400×400px | 1:1 | PNG/JPEG |
| Collections | 600×500px | 6:5 | JPEG |
| Brands | 300×300px | 1:1 | PNG |
| Testimonials | 200×200px | 1:1 | PNG/JPEG |

**Note:** These are recommended sizes. iOS will scale appropriately, but providing 2x and 3x versions ensures crisp display on all devices.

## Asset Naming Conventions

✅ **Good:**
- `product1`, `product2` (lowercase, no spaces)
- `collection_haircare` (underscores for separation)
- `brand_ny` (abbreviated, clear)

❌ **Avoid:**
- `Product 1` (spaces)
- `Hair-Care-Collection` (hyphens, capital letters)
- `brand.ny` (periods can cause issues)

## Optional Enhancements

### Additional Images You Might Want:

- [ ] `app_icon` - App icon (1024×1024px)
- [ ] `launch_screen_logo` - Launch screen logo
- [ ] `placeholder_product` - Generic product placeholder
- [ ] `empty_state_cart` - Empty cart illustration
- [ ] `empty_state_favorites` - Empty favorites illustration

### Icon Assets:

- [ ] Custom icons for navigation (if not using SF Symbols)
- [ ] Social media icons (Instagram, Facebook, etc.)

## Progress Tracking

**Overall Progress:** ___ / 25 assets

**Status:**
- 🔴 Not Started
- 🟡 In Progress (collecting/editing images)
- 🟢 Complete (added to Xcode)

---

**Tips:**
1. Start with Priority 1 and 2 for a functional home screen
2. Ensure all images are high quality and properly sized
3. Compress images to reduce app size (use tools like ImageOptim)
4. Test on different device sizes to ensure images look good
5. Keep original files backed up separately

**Need help?** 
- Finding similar products? Check your website's image library
- Image sizing? Use Preview (Mac), Photoshop, or online tools
- Bulk processing? Consider using ImageMagick or similar tools
