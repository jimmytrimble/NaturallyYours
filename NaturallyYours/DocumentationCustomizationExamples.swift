//
//  CustomizationExamples.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/28/26.
//
//  This file contains example code snippets for common customizations.
//  NOT meant to be compiled - just reference for copy/paste.
//

import SwiftUI

// MARK: - Example 1: Using ViewModel with HomeView

/*
 If you want to use the HomeViewModel instead of sample data:

 1. Update HomeView to accept a view model:
 
struct HomeView: View {
    @ObservedObject var authService: AuthService
    @State private var viewModel = HomeViewModel()  // Add this
    @State private var emailForNewsletter = ""
    @State private var showingNewsletterSuccess = false
    
    var body: some View {
        // ...
    }
}

 2. Replace sample data with view model data:
 
 // Instead of:
 ForEach(FeaturedProduct.sampleData) { product in
     ProductCard(product: product)
 }
 
 // Use:
 ForEach(viewModel.featuredProducts) { product in
     ProductCard(product: product)
 }

 3. Add loading state:
 
 .task {
     await viewModel.fetchHomeData()
 }
 .overlay {
     if viewModel.isLoading {
         ProgressView()
             .scaleEffect(1.5)
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(Color.nyWhite.opacity(0.8))
     }
 }
*/

// MARK: - Example 2: Navigation to Product Detail

/*
 To navigate to a product detail view when tapping a product card:

struct ProductCard: View {
    let product: FeaturedProduct
    
    var body: some View {
        NavigationLink(value: product) {  // Wrap in NavigationLink
            VStack(alignment: .leading, spacing: 12) {
                // ... existing content
            }
            .frame(width: 180)
            .padding(12)
            .background(Color.nyWhite)
            .cornerRadius(12)
            .nyCardShadow()
        }
        .buttonStyle(.plain)  // Remove default button styling
    }
}

// In HomeView, add navigation destination:

.navigationDestination(for: FeaturedProduct.self) { product in
    ProductDetailView(product: product)
}
*/

// MARK: - Example 3: Pull to Refresh

/*
 Add pull-to-refresh functionality:

struct HomeView: View {
    @ObservedObject var authService: AuthService
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // ... content
            }
            .refreshable {
                await viewModel.fetchHomeData()
            }
        }
    }
}
*/

// MARK: - Example 4: Search Bar in Navigation

/*
 Add a search bar to the navigation:

struct HomeView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // ... content
            }
            .searchable(text: $searchText, prompt: "Search products")
        }
    }
}
*/

// MARK: - Example 5: Infinite Scrolling for Products

/*
 Load more products as user scrolls:

struct FeaturedBestSellersSection: View {
    @Binding var products: [FeaturedProduct]
    let loadMore: () async -> Void
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(products) { product in
                        ProductCard(product: product)
                            .onAppear {
                                if product == products.last {
                                    Task {
                                        await loadMore()
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}
*/

// MARK: - Example 6: Animated Hero Section

/*
 Add parallax effect to hero section:

struct HeroSection: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color.nySoftPink, Color.nyLightPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(y: scrollOffset * 0.5)  // Parallax effect
                
                VStack {
                    // ... content
                }
            }
            .onAppear {
                // Track scroll position
            }
        }
    }
}
*/

// MARK: - Example 7: Product Favorites/Wishlist

/*
 Add heart button to save favorites:

struct ProductCard: View {
    let product: FeaturedProduct
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Product image
                
                // Favorite button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isFavorite.toggle()
                        // Save to favorites
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(isFavorite ? .nyPink : .nyGray)
                        .padding(8)
                        .background(Circle().fill(Color.nyWhite.opacity(0.9)))
                        .shadow(radius: 2)
                }
                .padding(8)
            }
            
            // ... rest of card
        }
    }
}
*/

// MARK: - Example 8: Add to Cart Button

/*
 Add quick "Add to Cart" functionality:

struct ProductCard: View {
    let product: FeaturedProduct
    @State private var isAddingToCart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ... existing content
            
            Button {
                Task {
                    await addToCart()
                }
            } label: {
                if isAddingToCart {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "cart.badge.plus")
                    Text("Add")
                }
            }
            .font(.nyCaption(13))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.nyPink)
            .cornerRadius(6)
        }
    }
    
    private func addToCart() async {
        isAddingToCart = true
        // Implement cart logic
        try? await Task.sleep(for: .seconds(0.5))
        isAddingToCart = false
    }
}
*/

// MARK: - Example 9: Custom Collection Layout

/*
 Create a more dynamic collection grid:

struct CollectionsSection: View {
    let collections: [CollectionCategory]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SHOP BY COLLECTION")
                .font(.nyHeading(24))
            
            // Adaptive grid that adjusts to screen size
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(collections) { collection in
                    CollectionCard(collection: collection)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
*/

// MARK: - Example 10: Animated Newsletter Success

/*
 Add confetti or celebration animation on newsletter signup:

import SwiftUI

struct NewsletterSection: View {
    @State private var emailForNewsletter = ""
    @State private var showingSuccess = false
    @State private var confettiCounter = 0
    
    var body: some View {
        VStack {
            // ... newsletter form
            
            Button("Subscribe") {
                subscribeToNewsletter()
            }
        }
        .confettiCannon(
            counter: $confettiCounter,
            num: 50,
            radius: 400
        )
    }
    
    private func subscribeToNewsletter() {
        // After successful subscription:
        withAnimation {
            showingSuccess = true
            confettiCounter += 1
        }
    }
}

// Note: You'll need to add a confetti package like:
// https://github.com/simibac/ConfettiSwiftUI
*/

// MARK: - Example 11: Skeleton Loading View

/*
 Show skeleton placeholders while loading:

struct ProductCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nyLightGray)
                .aspectRatio(1, contentMode: .fit)
                .shimmer(isAnimating)
            
            // Text skeletons
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.nyLightGray)
                .frame(height: 12)
                .shimmer(isAnimating)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.nyLightGray)
                .frame(height: 16)
                .frame(width: 100)
                .shimmer(isAnimating)
        }
        .frame(width: 180)
        .padding(12)
        .onAppear {
            isAnimating = true
        }
    }
}

extension View {
    func shimmer(_ isActive: Bool) -> some View {
        self.overlay(
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.6),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(isActive ? 1 : 0)
            .animation(
                .linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isActive
            )
        )
    }
}
*/

// MARK: - Example 12: Error Handling UI

/*
 Display errors gracefully:

struct ErrorView: View {
    let message: String
    let retryAction: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.nyPink)
            
            Text("Oops!")
                .font(.nyHeading(24))
            
            Text(message)
                .font(.nyBody(16))
                .foregroundStyle(.nyGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await retryAction()
                }
            } label: {
                Text("Try Again")
                    .font(.nyBody(16))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.nyPink)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// In HomeView:
if let error = viewModel.errorMessage {
    ErrorView(message: error) {
        await viewModel.fetchHomeData()
    }
} else {
    // Normal content
}
*/

// MARK: - Example 13: Analytics Tracking

/*
 Track user interactions:

extension HomeView {
    private func trackProductTap(_ product: FeaturedProduct) {
        // Using your analytics service
        AnalyticsService.shared.track(
            event: "product_tapped",
            parameters: [
                "product_id": product.id.uuidString,
                "product_name": product.name,
                "screen": "home"
            ]
        )
    }
    
    private func trackNewsletterSignup() {
        AnalyticsService.shared.track(
            event: "newsletter_signup",
            parameters: ["screen": "home"]
        )
    }
}
*/

// MARK: - Example 14: Deep Linking Support

/*
 Handle deep links to specific products or collections:

struct HomeView: View {
    @State private var selectedProduct: FeaturedProduct?
    
    var body: some View {
        NavigationStack {
            // ... content
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Example: naturallyyours://product/123
        if url.scheme == "naturallyyours",
           url.host == "product",
           let productId = url.pathComponents.last {
            // Navigate to product
        }
    }
}
*/

// MARK: - Example 15: Accessibility Improvements

/*
 Make the app more accessible:

struct ProductCard: View {
    let product: FeaturedProduct
    
    var body: some View {
        VStack {
            // ... content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name) by \(product.brand)")
        .accessibilityValue("Price: \(product.formattedPrice), Rating: \(product.rating) out of 5 stars")
        .accessibilityHint("Double tap to view product details")
        .accessibilityAddTraits(.isButton)
    }
}

struct TestimonialCard: View {
    let testimonial: CustomerTestimonial
    
    var body: some View {
        VStack {
            // ... content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Customer review")
        .accessibilityValue("\(testimonial.testimonial). Rating: \(testimonial.rating) stars by \(testimonial.customerName)")
    }
}
*/
