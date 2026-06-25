# Home Screen Architecture

## File Structure

```
NaturallyYours/
│
├── Views/
│   └── HomeView.swift                    ⭐ MAIN HOME SCREEN
│       ├── Hero Section
│       ├── Featured Best Sellers
│       ├── Collections Section
│       ├── Featured Brands
│       ├── Customer Testimonials
│       └── Newsletter Section
│
├── ViewModels/
│   └── HomeViewModel.swift               🎯 DATA MANAGEMENT
│       ├── Loads featured products
│       ├── Loads brands
│       ├── Loads testimonials
│       ├── Handles newsletter signup
│       └── Ready for API integration
│
├── Models/
│   └── HomeModels.swift                  📦 DATA STRUCTURES
│       ├── FeaturedProduct
│       ├── FeaturedBrand
│       ├── CustomerTestimonial
│       ├── CollectionCategory
│       └── Sample data for testing
│
├── Extensions/
│   ├── Color+Theme.swift                 🎨 COLORS
│   │   ├── nyPink (#F28CBD)
│   │   ├── nyLightPink (#FBDCE8)
│   │   ├── nySoftPink (#FDF2F7)
│   │   ├── nyBlack
│   │   ├── nyWhite
│   │   └── Shadow utilities
│   │
│   └── Font+Theme.swift                  ✍️ TYPOGRAPHY
│       ├── nyLogoFont() - Handwritten style
│       ├── nyHeading() - Bold headers
│       ├── nySubheading() - Sections
│       ├── nyBody() - Regular text
│       └── nyCaption() - Small text
│
├── Services/
│   └── AuthService.swift                 🔐 EXISTING AUTH
│       └── (Already integrated)
│
├── Documentation/
│   ├── README.md                         📖 THIS OVERVIEW
│   ├── HomeScreenGuide.md                🛠️ SETUP GUIDE
│   ├── StyleGuide.md                     🎨 DESIGN SPECS
│   ├── AssetChecklist.md                 ✅ IMAGE LIST
│   └── CustomizationExamples.swift       💡 CODE SNIPPETS
│
└── Assets.xcassets/                      🖼️ YOUR IMAGES GO HERE
    ├── hero_image
    ├── product1, product2, product3...
    ├── collection_haircare, styling...
    ├── brand_ny, brand_shea...
    └── testimonial1, testimonial2...
```

## Component Hierarchy

```
HomeView
│
├── NavigationStack
│   └── Toolbar
│       ├── Logo (center)
│       ├── Menu (left)
│       └── Cart (right)
│
└── ScrollView
    │
    ├── 1. Hero Section
    │   ├── "Naturally Yours" Logo (large)
    │   ├── "Beauty Supply" subtitle
    │   ├── Hero Image
    │   ├── Tagline
    │   └── "Shop Now" Button
    │
    ├── 2. Featured Best Sellers
    │   ├── Section Title
    │   └── Horizontal ScrollView
    │       └── [ProductCard, ProductCard, ProductCard...]
    │           ├── Product Image
    │           ├── "BEST SELLER" Badge
    │           ├── Brand Name
    │           ├── Product Name
    │           ├── Star Rating
    │           └── Price
    │
    ├── 3. Collections
    │   ├── Section Title
    │   └── Grid Layout
    │       └── [CollectionCard, CollectionCard...]
    │           ├── Collection Image
    │           ├── Collection Name
    │           └── Product Count
    │
    ├── 4. Featured Brands
    │   ├── Section Title
    │   └── Horizontal ScrollView
    │       └── [BrandCard, BrandCard...]
    │           ├── Brand Logo (circle)
    │           └── Brand Name
    │
    ├── 5. Customer Testimonials
    │   ├── Section Title
    │   └── Horizontal ScrollView
    │       └── [TestimonialCard, TestimonialCard...]
    │           ├── Star Rating
    │           ├── Testimonial Text
    │           ├── Customer Photo
    │           └── Customer Name
    │
    └── 6. Newsletter Section
        ├── Section Title
        ├── Description
        └── Signup Form
            ├── Email TextField
            └── Subscribe Button
```

## Data Flow

```
┌─────────────────────┐
│   HomeView.swift    │  ← Main UI
└──────────┬──────────┘
           │
           │ Uses
           ▼
┌─────────────────────┐
│  HomeViewModel      │  ← State & Logic
└──────────┬──────────┘
           │
           │ Loads
           ▼
┌─────────────────────┐
│  HomeModels.swift   │  ← Data Structures
│  - FeaturedProduct  │
│  - FeaturedBrand    │
│  - Testimonial      │
│  - Collection       │
└─────────────────────┘
           │
           │ Displays with
           ▼
┌─────────────────────┐
│ Color + Font Theme  │  ← Styling
└─────────────────────┘
```

## Current State vs. Future State

### Current (What You Have Now):

```
HomeView
    │
    ├── ✅ Beautiful UI (implemented)
    ├── ✅ Brand colors (implemented)
    ├── ✅ Typography system (implemented)
    ├── 📦 Sample data (hardcoded)
    └── 🖼️ Placeholder images (needs your assets)
```

### Future (After Adding Assets & API):

```
HomeView
    │
    ├── ✅ Beautiful UI
    ├── ✅ Brand colors
    ├── ✅ Typography system
    ├── 🌐 Live data (from API)
    └── 🖼️ Real images (your products)
```

## Color Usage Map

```
Component              Background    Text/Icons    Accents
──────────────────────────────────────────────────────────
Hero Section           nySoftPink    nyBlack       -
Product Cards          nyWhite       nyBlack       nyPink (badge)
Collection Cards       nyWhite       nyBlack       nyLightPink
Brand Cards            nyWhite       nyBlack       -
Testimonial Cards      nyWhite       nyBlack       nyPink (stars)
Newsletter Section     nySoftPink    nyBlack       nyPink (button)
Navigation Bar         nyWhite       nyBlack       -
Buttons (Primary)      nyBlack       nyWhite       -
Buttons (Secondary)    nyPink        nyWhite       -
```

## Typography Usage Map

```
Element                Font              Size    Weight
──────────────────────────────────────────────────────────
Logo (Large)           nyLogoFont()      42pt    Medium
Logo (Nav)             nyLogoFont()      22pt    Medium
Section Titles         nyHeading()       24pt    Bold
Product Names          nyBody()          15pt    Semibold
Brand Names            nyCaption()       12pt    Regular
Prices                 nySubheading()    17pt    Bold
Buttons                nyBody()          16pt    Semibold
Body Text              nyBody()          16pt    Regular
Captions               nyCaption()       14pt    Regular
```

## Asset Naming Convention

```
Type              Format                     Example
────────────────────────────────────────────────────────────
Products          product{number}            product1
Collections       collection_{name}          collection_haircare
Brands            brand_{abbrev}             brand_ny
Testimonials      testimonial{number}        testimonial1
Hero              hero_image                 hero_image
```

## Navigation Flow (Future Implementation)

```
Login/Register
      │
      └──> HomeView (Current Page) ──┐
                │                     │
                ├──> Product Detail   │
                ├──> Collection View  │
                ├──> Brand Page       │
                ├──> Search Results   │
                ├──> Cart             │
                └──> Profile          │
                     │                │
                     └────────────────┘
```

## Customization Points

```
Easy to Change:
├── Colors          → Color+Theme.swift
├── Fonts           → Font+Theme.swift
├── Sample Data     → HomeModels.swift
├── Layout Spacing  → HomeView.swift
├── Images          → Assets.xcassets
└── API Endpoints   → HomeViewModel.swift

Medium Complexity:
├── Add new sections
├── Change grid layouts
├── Add animations
├── Navigation flows
└── Filtering/sorting

Advanced:
├── API integration
├── State management
├── Caching strategy
├── Performance optimization
└── Custom animations
```

## Quick Reference: Where to Make Changes

```
Want to...                          Edit this file...
────────────────────────────────────────────────────────────
Change pink color                   Extensions/Color+Theme.swift
Change logo font                    Extensions/Font+Theme.swift
Add more products                   Models/HomeModels.swift
Add hero image                      Assets.xcassets + HomeView.swift
Rearrange sections                  Views/HomeView.swift
Connect to API                      ViewModels/HomeViewModel.swift
Change spacing                      Views/HomeView.swift
Add new component                   Views/HomeView.swift
Update navigation                   Views/HomeView.swift
Change button style                 Extensions/Color+Theme.swift
```

## Performance Considerations

```
Optimized:
✅ Lazy loading with ScrollView
✅ Efficient image loading
✅ Minimal state updates
✅ Async/await for network calls

To Optimize Further:
□ Image caching
□ Pagination for products
□ Lazy loading for images
□ Memory management for large lists
```

## Testing Checklist

```
□ Run on iPhone SE (small screen)
□ Run on iPhone 15 Pro Max (large screen)
□ Test in light mode
□ Test in dark mode
□ Test with slow network
□ Test with no images
□ Test scroll performance
□ Test navigation
□ Test accessibility (VoiceOver)
```

---

This architecture provides:
- ✅ Separation of concerns (UI, Logic, Data)
- ✅ Easy customization
- ✅ Scalable structure
- ✅ Well-documented
- ✅ Ready for API integration
- ✅ Brand-consistent design
