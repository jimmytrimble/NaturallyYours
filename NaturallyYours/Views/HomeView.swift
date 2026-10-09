import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var authService: AuthService
    @Binding var selectedTab: MainTabView.Tab
    @Environment(ProductService.self) private var productService
    @State private var emailForNewsletter = ""
    @State private var showingNewsletterSuccess = false
    @State private var showingContact = false

    /// Live "best sellers": on-sale products first, otherwise the newest arrivals.
    private var featured: [CatalogProduct] {
        let sale = productService.products.filter { $0.onSale && $0.inStock }
        let base = sale.isEmpty ? productService.products : sale
        return Array(base.prefix(8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section with Brand Logo
                    heroSection
                    
                    // Featured Best Sellers
                    featuredBestSellersSection
                    
                    // Collections Section
                    collectionsSection
                    
                    // Featured Brands
                    featuredBrandsSection
                    
                    // Customer Testimonials
                    testimonialsSection
                    
                    // Newsletter Section
                    newsletterSection
                    
                    // Footer Spacer
                    Color.clear.frame(height: 40)
                }
            }
            .background(Color.nyWhite)
            .navigationDestination(for: CatalogProduct.self) { product in
                ProductDetailView(product: product)
            }
            .task { await productService.loadProducts() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedTab = .cart
                    } label: {
                        Image(systemName: "cart")
                            .foregroundStyle(.nyBlack)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if authService.isAuthenticated {
                            Button {
                                selectedTab = .account
                            } label: {
                                Label("Profile", systemImage: "person")
                            }

                            Button {
                                selectedTab = .account
                            } label: {
                                Label("Orders", systemImage: "bag")
                            }
                        }

                        Button {
                            showingContact = true
                        } label: {
                            Label("Contact Us", systemImage: "envelope")
                        }

                        Divider()

                        if authService.isAuthenticated {
                            Button(role: .destructive) {
                                Task { try? await authService.logout() }
                            } label: {
                                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } else {
                            Button {
                                // Return to the login screen (guest has no server session).
                                authService.isGuest = false
                                authService.isAuthenticated = false
                                authService.currentUser = nil
                            } label: {
                                Label("Log In", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.nyBlack)
                    }
                }
            }
            .sheet(isPresented: $showingContact) {
                ContactView()
                    .environmentObject(authService)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Thank You!", isPresented: $showingNewsletterSuccess) {
                Button("OK") { }
            } message: {
                Text("You've been added to our mailing list!")
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        ZStack {
            // Background gradient - softer, like website
            LinearGradient(
                colors: [Color.nySoftPink, Color.nyLightPink.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 16) {
                // Handwritten-style "Naturally Yours" using Zapfino font
                Text("Naturally Yours")
                    .font(.custom("Zapfino", size: 38))
                    .foregroundStyle(.nyBlack)
                    .padding(.top, 20)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text("Beauty Supply")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(.nyBlack)
                    .tracking(2)
                    .padding(.top, -8)
                
                // Hero image - larger and more prominent
                Image("header_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Text("Shop all of our latest products")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundStyle(.nyGray)
                    .italic()
                    .padding(.top, 12)
                
                Button {
                    selectedTab = .shop
                } label: {
                    Text("Shop Now")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 16)
                        .background(Color.nyBlack)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Featured Best Sellers Section
    
    @ViewBuilder
    private var featuredBestSellersSection: some View {
        if !featured.isEmpty {
            VStack(spacing: 20) {
                Text("FEATURED BEST SELLERS")
                    .font(.nyHeading(24))
                    .foregroundStyle(.nyBlack)
                    .padding(.top, 40)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(featured) { product in
                            NavigationLink(value: product) {
                                ShopProductCard(product: product)
                                    .frame(width: 180)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Collections Section
    
    @ViewBuilder
    private var collectionsSection: some View {
        if !productService.categories.isEmpty {
            VStack(spacing: 20) {
                Text("SHOP BY COLLECTION")
                    .font(.nyHeading(24))
                    .foregroundStyle(.nyBlack)
                    .padding(.top, 20)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(productService.categories, id: \.self) { category in
                        NavigationLink {
                            ShopView(initialCategory: category)
                        } label: {
                            HomeCollectionTile(
                                name: category,
                                count: productService.products(in: category).count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Featured Brands Section
    
    private var featuredBrandsSection: some View {
        VStack(spacing: 20) {
            Text("FEATURED BRANDS")
                .font(.nyHeading(24))
                .foregroundStyle(.nyBlack)
                .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(FeaturedBrand.sampleData) { brand in
                        BrandCard(brand: brand)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Testimonials Section
    
    private var testimonialsSection: some View {
        VStack(spacing: 20) {
            Text("CUSTOMER TESTIMONIALS")
                .font(.nyHeading(24))
                .foregroundStyle(.nyBlack)
                .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(CustomerTestimonial.sampleData) { testimonial in
                        TestimonialCard(testimonial: testimonial)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Newsletter Section
    
    private var newsletterSection: some View {
        VStack(spacing: 20) {
            Text("JOIN OUR MAILING LIST")
                .font(.nyHeading(24))
                .foregroundStyle(.nyBlack)
            
            Text("Get exclusive offers and updates")
                .font(.nyBody(16))
                .foregroundStyle(.nyGray)
            
            HStack(spacing: 12) {
                TextField("Enter your email", text: $emailForNewsletter)
                    .textFieldStyle(.plain)
                    .font(.nyBody(15))
                    .padding()
                    .background(Color.nyLightGray)
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                Button {
                    subscribeToNewsletter()
                } label: {
                    Text("Subscribe")
                        .font(.nyBody(15))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.nyPink)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
        .background(Color.nySoftPink)
    }
    
    // MARK: - Helper Methods
    
    private func subscribeToNewsletter() {
        // TODO: Implement newsletter subscription API call
        guard !emailForNewsletter.isEmpty else { return }
        
        showingNewsletterSuccess = true
        emailForNewsletter = ""
    }
}

// MARK: - Product Card Component

struct ProductCard: View {
    let product: FeaturedProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nyLightGray)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.nyGray.opacity(0.3))
                        // Replace with: Image(product.imageName)
                    }
                
                // Badge
                if product.isBestSeller {
                    Text("BEST SELLER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.nyPink)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand)
                    .font(.nyCaption(12))
                    .foregroundStyle(.nyGray)
                
                Text(product.name)
                    .font(.nyBody(15))
                    .foregroundStyle(.nyBlack)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(product.rating) ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(.nyPink)
                    }
                    Text("(\(product.reviewCount))")
                        .font(.system(size: 10))
                        .foregroundStyle(.nyGray)
                }
                
                Text(product.formattedPrice)
                    .font(.nySubheading(17))
                    .foregroundStyle(.nyBlack)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 180)
        .padding(12)
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }
}

// MARK: - Collection Card Component

struct CollectionCard: View {
    let collection: CollectionCategory
    
    var body: some View {
        VStack(spacing: 0) {
            // Collection Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nyLightPink.opacity(0.3))
                .aspectRatio(1.2, contentMode: .fit)
                .overlay {
                    Image(systemName: "square.grid.2x2")
                        .font(.largeTitle)
                        .foregroundStyle(.nyPink.opacity(0.5))
                    // Replace with: Image(collection.imageName)
                }
            
            // Collection Info
            VStack(spacing: 6) {
                Text(collection.name)
                    .font(.nySubheading(16))
                    .foregroundStyle(.nyBlack)
                    .fontWeight(.bold)
                
                Text("\(collection.productCount) Products")
                    .font(.nyCaption(13))
                    .foregroundStyle(.nyGray)
            }
            .padding(.vertical, 12)
        }
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }
}

// MARK: - Home Collection Tile (live categories)

struct HomeCollectionTile: View {
    let name: String
    let count: Int

    private var iconName: String {
        switch name {
        case "Bundles": return "shippingbox"
        case "Skincare": return "sparkles"
        case "Haircare": return "comb"
        case "Treatments": return "drop"
        case "Men": return "person"
        default: return "square.grid.2x2"
        }
    }

    /// Asset name for the category thumbnail, if one exists.
    private var imageAsset: String? {
        switch name {
        case "Bundles": return "collection_bundles"
        case "Skincare": return "collection_skincare"
        case "Haircare": return "collection_haircare"
        case "Treatments": return "collection_treatments"
        case "Men": return "collection_men"
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.nyLightPink.opacity(0.3)
                .aspectRatio(1.2, contentMode: .fit)
                .overlay {
                    if let imageAsset {
                        Image(imageAsset)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: iconName)
                            .font(.largeTitle)
                            .foregroundStyle(.nyPink.opacity(0.6))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 6) {
                Text(name)
                    .font(.nySubheading(16))
                    .foregroundStyle(.nyBlack)
                    .fontWeight(.bold)

                Text("\(count) \(count == 1 ? "Product" : "Products")")
                    .font(.nyCaption(13))
                    .foregroundStyle(.nyGray)
            }
            .padding(.vertical, 12)
        }
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }
}

// MARK: - Brand Card Component

struct BrandCard: View {
    let brand: FeaturedBrand

    /// Initials used for the fallback brand mark (e.g. "Design Essentials" → "DE").
    private var monogram: String {
        let words = brand.name.split(separator: " ")
        if words.count >= 2 {
            return words.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
        }
        return String(brand.name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.nyWhite)
                .frame(width: 100, height: 100)
                .overlay {
                    // Use the official logo if one has been added to the asset catalog,
                    // otherwise show a clean monogram badge.
                    if UIImage(named: brand.logoImageName) != nil {
                        Image(brand.logoImageName)
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                            .clipShape(Circle())
                    } else {
                        Text(monogram)
                            .font(.system(size: 30, weight: .semibold, design: .serif))
                            .foregroundStyle(.nyPink)
                    }
                }
                .overlay(
                    Circle().stroke(Color.nyLightPink, lineWidth: 1.5)
                )
                .nyElevationShadow()

            Text(brand.name)
                .font(.nyBody(15))
                .foregroundStyle(.nyBlack)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 120)
    }
}

// MARK: - Testimonial Card Component

struct TestimonialCard: View {
    let testimonial: CustomerTestimonial
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Rating Stars
            HStack(spacing: 4) {
                ForEach(0..<testimonial.rating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.nyPink)
                }
            }
            
            // Testimonial Text
            Text(testimonial.testimonial)
                .font(.nyBody(15))
                .foregroundStyle(.nyBlack)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Customer Info
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.nyLightPink)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.nyPink)
                    }
                // Replace with customer image if available
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(testimonial.customerName)
                        .font(.nyBody(14))
                        .foregroundStyle(.nyBlack)
                        .fontWeight(.semibold)
                    
                    Text("Verified Customer")
                        .font(.nyCaption(12))
                        .foregroundStyle(.nyGray)
                }
            }
        }
        .frame(width: 280, height: 200)
        .padding(20)
        .background(Color.nyWhite)
        .cornerRadius(12)
        .nyCardShadow()
    }
}

// MARK: - Previews

#Preview {
    let authService = AuthService()
    authService.currentUser = UserDTO(
        id: UUID(),
        name: "John Smith",
        email: "john@example.com"
    )
    authService.isAuthenticated = true

    return HomeView(authService: authService, selectedTab: .constant(.home))
        .environment(ProductService())
}
