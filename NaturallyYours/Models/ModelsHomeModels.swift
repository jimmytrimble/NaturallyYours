import Foundation

// MARK: - Featured Product

struct FeaturedProduct: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String
    let price: Double
    let imageName: String // Asset name
    let rating: Double
    let reviewCount: Int
    let isNewArrival: Bool
    let isBestSeller: Bool
    
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        price: Double,
        imageName: String,
        rating: Double = 5.0,
        reviewCount: Int = 0,
        isNewArrival: Bool = false,
        isBestSeller: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.price = price
        self.imageName = imageName
        self.rating = rating
        self.reviewCount = reviewCount
        self.isNewArrival = isNewArrival
        self.isBestSeller = isBestSeller
    }
}

// MARK: - Featured Brand

struct FeaturedBrand: Identifiable, Codable {
    let id: UUID
    let name: String
    let logoImageName: String // Asset name
    let description: String
    
    init(
        id: UUID = UUID(),
        name: String,
        logoImageName: String,
        description: String
    ) {
        self.id = id
        self.name = name
        self.logoImageName = logoImageName
        self.description = description
    }
}

// MARK: - Customer Testimonial

struct CustomerTestimonial: Identifiable, Codable {
    let id: UUID
    let customerName: String
    let customerImageName: String? // Optional asset name
    let testimonial: String
    let rating: Int
    let date: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    init(
        id: UUID = UUID(),
        customerName: String,
        customerImageName: String? = nil,
        testimonial: String,
        rating: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.customerName = customerName
        self.customerImageName = customerImageName
        self.testimonial = testimonial
        self.rating = rating
        self.date = date
    }
}

// MARK: - Collection Category

struct CollectionCategory: Identifiable, Codable {
    let id: UUID
    let name: String
    let imageName: String // Asset name
    let productCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        imageName: String,
        productCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.productCount = productCount
    }
}

// MARK: - Sample Data

extension FeaturedProduct {
    static let sampleData: [FeaturedProduct] = [
        FeaturedProduct(
            name: "Curl Defining Cream",
            brand: "Naturally Yours",
            price: 24.99,
            imageName: "product1",
            rating: 4.8,
            reviewCount: 234,
            isBestSeller: true
        ),
        FeaturedProduct(
            name: "Moisture Lock Shampoo",
            brand: "Natural Hair Co.",
            price: 18.99,
            imageName: "product2",
            rating: 4.9,
            reviewCount: 567,
            isBestSeller: true
        ),
        FeaturedProduct(
            name: "Edge Control",
            brand: "Naturally Yours",
            price: 12.99,
            imageName: "product3",
            rating: 4.7,
            reviewCount: 189,
            isNewArrival: true
        ),
        FeaturedProduct(
            name: "Deep Conditioner",
            brand: "Natural Hair Co.",
            price: 29.99,
            imageName: "product4",
            rating: 5.0,
            reviewCount: 412,
            isBestSeller: true
        )
    ]
}

extension FeaturedBrand {
    // `logoImageName` is the asset name the card will use if a matching image exists in
    // the asset catalog; otherwise the card falls back to a styled monogram badge. Drop
    // official logo PNGs in with these names to light them up automatically.
    static let sampleData: [FeaturedBrand] = [
        FeaturedBrand(
            name: "Annie",
            logoImageName: "brand_annie",
            description: "Hair accessories & styling tools"
        ),
        FeaturedBrand(
            name: "G Series",
            logoImageName: "brand_g_series",
            description: "Professional hair care"
        ),
        FeaturedBrand(
            name: "Naked",
            logoImageName: "brand_naked",
            description: "Honey & almond moisture"
        ),
        FeaturedBrand(
            name: "Design Essentials",
            logoImageName: "brand_design_essentials",
            description: "Salon-quality textured hair care"
        ),
        FeaturedBrand(
            name: "Nairobi",
            logoImageName: "brand_nairobi",
            description: "Professional hair care"
        ),
        FeaturedBrand(
            name: "Essations",
            logoImageName: "brand_essations",
            description: "Professional hair & skin care"
        )
    ]
}

extension CustomerTestimonial {
    static let sampleData: [CustomerTestimonial] = [
        CustomerTestimonial(
            customerName: "Jasmine Williams",
            customerImageName: "testimonial1",
            testimonial: "The best products for natural hair! My curls have never looked better. Highly recommend!",
            rating: 5
        ),
        CustomerTestimonial(
            customerName: "Maya Johnson",
            customerImageName: "testimonial2",
            testimonial: "Fast shipping and great customer service. Love the quality of these products!",
            rating: 5
        ),
        CustomerTestimonial(
            customerName: "Aisha Davis",
            customerImageName: "testimonial3",
            testimonial: "Finally found a store that understands natural hair needs. Will definitely shop again!",
            rating: 5
        )
    ]
}

extension CollectionCategory {
    static let sampleData: [CollectionCategory] = [
        CollectionCategory(name: "Hair Care", imageName: "collection_haircare", productCount: 145),
        CollectionCategory(name: "Styling", imageName: "collection_styling", productCount: 89),
        CollectionCategory(name: "Treatments", imageName: "collection_treatments", productCount: 67),
        CollectionCategory(name: "Accessories", imageName: "collection_accessories", productCount: 52)
    ]
}
