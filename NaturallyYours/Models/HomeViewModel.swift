import Foundation
import Observation

@Observable
final class HomeViewModel {
    
    // MARK: - Published Properties
    
    var featuredProducts: [FeaturedProduct] = []
    var featuredBrands: [FeaturedBrand] = []
    var testimonials: [CustomerTestimonial] = []
    var collections: [CollectionCategory] = []
    
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Initialization
    
    init() {
        loadSampleData()
    }
    
    // MARK: - Data Loading
    
    /// Load sample data for development
    func loadSampleData() {
        featuredProducts = FeaturedProduct.sampleData
        featuredBrands = FeaturedBrand.sampleData
        testimonials = CustomerTestimonial.sampleData
        collections = CollectionCategory.sampleData
    }
    
    /// Fetch data from API (implement when backend is ready)
    func fetchHomeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Replace with actual API calls
            // Example:
            // async let products = homeService.fetchFeaturedProducts()
            // async let brands = homeService.fetchFeaturedBrands()
            // async let testimonials = homeService.fetchTestimonials()
            // async let collections = homeService.fetchCollections()
            
            // let (p, b, t, c) = try await (products, brands, testimonials, collections)
            // self.featuredProducts = p
            // self.featuredBrands = b
            // self.testimonials = t
            // self.collections = c
            
            // For now, simulate network delay
            try await Task.sleep(for: .seconds(0.5))
            loadSampleData()
            
        } catch {
            errorMessage = "Failed to load home data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Subscribe to newsletter
    func subscribeToNewsletter(email: String) async throws {
        guard !email.isEmpty else {
            throw NewsletterError.invalidEmail
        }
        
        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            throw NewsletterError.invalidEmail
        }
        
        // TODO: Implement actual API call
        // Example:
        // try await homeService.subscribeToNewsletter(email)
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.5))
    }
}

// MARK: - Errors

enum NewsletterError: LocalizedError {
    case invalidEmail
    case subscriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .subscriptionFailed:
            return "Failed to subscribe. Please try again."
        }
    }
}

// MARK: - Home Service (Placeholder)

/// Service for fetching home screen data from API
/// Implement this when your backend is ready
final class HomeService {
    
    private let apiBaseURL: String
    
    init(apiBaseURL: String = AppConfiguration.apiBaseURL) {
        self.apiBaseURL = apiBaseURL
    }
    
    // MARK: - API Methods (To be implemented)
    
    func fetchFeaturedProducts() async throws -> [FeaturedProduct] {
        // TODO: Implement API call
        // let url = URL(string: "\(apiBaseURL)/products/featured")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([FeaturedProduct].self, from: data)
        
        return FeaturedProduct.sampleData
    }
    
    func fetchFeaturedBrands() async throws -> [FeaturedBrand] {
        // TODO: Implement API call
        return FeaturedBrand.sampleData
    }
    
    func fetchTestimonials() async throws -> [CustomerTestimonial] {
        // TODO: Implement API call
        return CustomerTestimonial.sampleData
    }
    
    func fetchCollections() async throws -> [CollectionCategory] {
        // TODO: Implement API call
        return CollectionCategory.sampleData
    }
    
    func subscribeToNewsletter(_ email: String) async throws {
        // TODO: Implement API call
        // let url = URL(string: "\(apiBaseURL)/newsletter/subscribe")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 
        // let body = ["email": email]
        // request.httpBody = try JSONEncoder().encode(body)
        // 
        // let (_, response) = try await URLSession.shared.data(for: request)
        // 
        // guard let httpResponse = response as? HTTPURLResponse,
        //       httpResponse.statusCode == 200 else {
        //     throw NewsletterError.subscriptionFailed
        // }
    }
}
