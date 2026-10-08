# Naturally Yours Home Screen Implementation Guide

## Overview
This document outlines the home screen implementation for the Naturally Yours Beauty Supply mobile app. The design follows the website's aesthetic with a white/black/pink color scheme and a handwritten-style logo.

## Files Created/Modified

### New Files:
1. **Extensions/Color+Theme.swift** - Brand color palette and styling utilities
2. **Extensions/Font+Theme.swift** - Custom typography system
3. **Models/HomeModels.swift** - Data models for home screen content
4. **Views/HomeView.swift** - Complete redesigned home screen (UPDATED)

## Features Implemented

### ✅ Hero Section
- Large "Naturally Yours" logo with handwritten-style font (customizable)
- Pink gradient background
- "Shop Now" call-to-action button
- Hero image placeholder

### ✅ Featured Best Sellers
- Horizontal scrolling product cards
- Product images (placeholder - ready for your assets)
- "BEST SELLER" badges
- Star ratings and review counts
- Price display

### ✅ Collections
- Grid layout of collection categories
- Links to different product collections
- Product counts for each category
- Visual cards with imagery

### ✅ Featured Brands
- Horizontal scrolling brand logos
- Circular brand cards
- Brand names and descriptions

### ✅ Customer Testimonials
- Horizontal scrolling testimonial cards
- 5-star ratings
- Customer names and verified badges
- Customer photos (placeholder)

### ✅ Newsletter Signup
- Email input field
- Subscribe button with pink styling
- Success confirmation alert
- Attractive section with pink background

### ✅ Navigation
- Top navigation bar with small logo
- Menu button (left) with profile and logout options
- Cart button (right)

## Color Scheme

The following brand colors are defined in `Color+Theme.swift`:

- **nyPink**: Primary pink (#F28CBD) - Main accent color
- **nyLightPink**: Light pink (#FBDCE8) - Secondary backgrounds
- **nySoftPink**: Very light pink (#FDF2F7) - Subtle backgrounds
- **nyBlack**: Pure black - Text and headers
- **nyWhite**: Pure white - Backgrounds
- **nyGray**: Medium gray - Secondary text
- **nyLightGray**: Very light gray - Input fields

## Typography

Custom font system in `Font+Theme.swift`:

- **nyLogoFont()**: Handwritten/script style for brand logo
- **nyHeading()**: Bold headers
- **nySubheading()**: Section subheadings
- **nyBody()**: Regular body text
- **nyCaption()**: Small text and labels

## Next Steps: Adding Your Assets

### 1. Product Images
Replace placeholder images in `ProductCard`:
```swift
// Current (line ~340):
Image(systemName: "photo")

// Replace with:
Image(product.imageName)
    .resizable()
    .aspectRatio(contentMode: .fill)
```

**Asset names needed:**
- `product1`, `product2`, `product3`, `product4`, etc.

### 2. Collection Images
Replace placeholder in `CollectionCard`:
```swift
// Current (line ~427):
Image(systemName: "square.grid.2x2")

// Replace with:
Image(collection.imageName)
    .resizable()
    .aspectRatio(contentMode: .fill)
```

**Asset names needed:**
- `collection_haircare`
- `collection_styling`
- `collection_treatments`
- `collection_accessories`

### 3. Brand Logos
Replace placeholder in `BrandCard`:
```swift
// Current (line ~463):
Image(systemName: "tag.fill")

// Replace with:
Image(brand.logoImageName)
    .resizable()
    .aspectRatio(contentMode: .fit)
```

**Asset names needed:**
- `brand_ny`, `brand_shea`, `brand_cantu`, `brand_mielle`

### 4. Customer Photos
Replace placeholder in `TestimonialCard`:
```swift
// Current (line ~510):
Circle()
    .fill(Color.nyLightPink)
    .overlay {
        Image(systemName: "person.fill")
    }

// Replace with:
if let imageName = testimonial.customerImageName {
    Image(imageName)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .clipShape(Circle())
} else {
    // Keep placeholder
}
```

**Asset names needed:**
- `testimonial1`, `testimonial2`, `testimonial3`

### 5. Hero Image
Replace placeholder in `heroSection`:
```swift
// Current (line ~124):
Image(systemName: "sparkles")

// Replace with:
Image("hero_image")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(maxHeight: 200)
```

**Asset name needed:**
- `hero_image` (the main banner image from your website)

## Adding Custom "Naturally Yours" Font

To use the exact handwritten font from your website logo:

1. **Get the font file** (e.g., `NaturallyYours.ttf` or `.otf`)

2. **Add to Xcode:**
   - Drag the font file into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to your target

3. **Update Info.plist:**
   - Add a new entry: "Fonts provided by application"
   - Add the exact font filename (including extension)

4. **Update Font+Theme.swift:**
   ```swift
   static func nyLogoFont(size: CGFloat = 34) -> Font {
       return .custom("YourExactFontName", size: size)
   }
   ```

5. **Find the font name:**
   - The font name might be different from the filename
   - You can print available fonts in your app:
   ```swift
   for family in UIFont.familyNames {
       print(family)
       for name in UIFont.fontNames(forFamilyName: family) {
           print("  \(name)")
       }
   }
   ```

## Updating Sample Data

Edit `HomeModels.swift` to update the sample data with your actual products:

```swift
extension FeaturedProduct {
    static let sampleData: [FeaturedProduct] = [
        FeaturedProduct(
            name: "Your Product Name",
            brand: "Brand Name",
            price: 24.99,
            imageName: "your_asset_name",
            rating: 4.8,
            reviewCount: 234,
            isBestSeller: true
        ),
        // Add more products...
    ]
}
```

## API Integration (Future)

When connecting to your backend:

1. Create a `HomeService.swift` to fetch data
2. Replace sample data with API calls
3. Add loading states
4. Handle errors gracefully

Example structure:
```swift
class HomeService {
    func fetchFeaturedProducts() async throws -> [FeaturedProduct] {
        // API call here
    }
    
    func subscribeToNewsletter(_ email: String) async throws {
        // API call here
    }
}
```

## Testing

Run the app and verify:
- [ ] Scrolling works smoothly
- [ ] All sections display properly
- [ ] Navigation bar is functional
- [ ] Newsletter form works
- [ ] Colors match brand (white/black/pink)
- [ ] Typography looks good on different screen sizes
- [ ] Images load (once added)

## Tips for Adding Images to Assets

1. **Open Assets.xcassets** in Xcode
2. **Click the + button** at the bottom
3. **Select "Image Set"**
4. **Name it exactly** as referenced in code (e.g., `product1`)
5. **Drag your image files** into the 1x, 2x, and 3x slots
   - 1x: Original size
   - 2x: 2× size (for Retina displays)
   - 3x: 3× size (for high-res displays)

## Recommended Image Sizes

- **Product images**: 400×400 px (square)
- **Collection images**: 600×500 px (landscape)
- **Brand logos**: 300×300 px (square, transparent background)
- **Hero image**: 1200×600 px (landscape)
- **Testimonial photos**: 200×200 px (square)

All images should be in PNG or JPEG format. Use PNG for images with transparency (like logos).

## Questions?

Feel free to ask about:
- Customizing colors
- Adjusting layouts
- Adding more sections
- Implementing navigation to detail pages
- API integration
- Any other modifications!

---

**Created:** May 28, 2026  
**Version:** 1.0  
**Status:** ✅ Ready for asset integration
