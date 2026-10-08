import Vapor
import Fluent

/// Seed command to populate database with sample products for testing
struct SeedProductsCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Flag(name: "clear", help: "Clear existing products before seeding")
        var clear: Bool
    }
    
    var help: String {
        "Seeds the database with sample products for testing"
    }
    
    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("🌱 Starting product seeding...")
        
        if signature.clear {
            context.console.print("🗑️  Clearing existing products...")
            try await Product.query(on: context.application.db).delete()
            context.console.print("✅ Products cleared")
        }
        
        let sampleProducts = [
            // Hair Care Products
            Product(
                name: "Coconut Hair Oil",
                description: "Pure coconut oil enriched with vitamin E for lustrous, healthy hair. Perfect for deep conditioning treatments and daily shine.",
                price: 24.99,
                salePrice: 19.99,
                category: "Hair Care",
                stockQuantity: 50,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800",
                    "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=800"
                ],
                sku: "HAIR-COCO-001",
                weight: 8.5,
                tags: ["organic", "vegan", "hair", "oil", "coconut"]
            ),
            Product(
                name: "Shea Butter Hair Mask",
                description: "Deep conditioning hair mask with organic shea butter. Repairs damaged hair and restores natural moisture balance.",
                price: 32.99,
                category: "Hair Care",
                stockQuantity: 35,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=800"
                ],
                sku: "HAIR-SHEA-001",
                weight: 10.0,
                tags: ["organic", "mask", "shea butter", "deep conditioning"]
            ),
            Product(
                name: "Argan Oil Leave-In Conditioner",
                description: "Lightweight leave-in conditioner with pure argan oil. Detangles, adds shine, and protects from heat damage.",
                price: 28.99,
                salePrice: 24.99,
                category: "Hair Care",
                stockQuantity: 45,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=800"
                ],
                sku: "HAIR-ARGA-001",
                weight: 6.0,
                tags: ["argan oil", "leave-in", "conditioner", "heat protection"]
            ),
            
            // Skin Care Products
            Product(
                name: "Vitamin C Face Serum",
                description: "Brightening serum with 20% vitamin C. Reduces dark spots, evens skin tone, and boosts collagen production.",
                price: 45.99,
                salePrice: 39.99,
                category: "Skin Care",
                stockQuantity: 60,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800"
                ],
                sku: "SKIN-VITC-001",
                weight: 1.0,
                tags: ["serum", "vitamin c", "brightening", "anti-aging"]
            ),
            Product(
                name: "Hyaluronic Acid Moisturizer",
                description: "Ultra-hydrating moisturizer with hyaluronic acid and ceramides. Plumps skin and locks in moisture all day.",
                price: 38.99,
                category: "Skin Care",
                stockQuantity: 55,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800"
                ],
                sku: "SKIN-HYAL-001",
                weight: 2.0,
                tags: ["moisturizer", "hyaluronic acid", "hydrating"]
            ),
            Product(
                name: "Gentle Cleansing Foam",
                description: "Sulfate-free cleansing foam that removes makeup and impurities without stripping natural oils. Perfect for all skin types.",
                price: 22.99,
                category: "Skin Care",
                stockQuantity: 70,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=800"
                ],
                sku: "SKIN-CLEA-001",
                weight: 5.0,
                tags: ["cleanser", "foam", "gentle", "makeup remover"]
            ),
            Product(
                name: "Retinol Night Cream",
                description: "Anti-aging night cream with 0.5% retinol. Reduces fine lines, wrinkles, and improves skin texture overnight.",
                price: 52.99,
                salePrice: 44.99,
                category: "Skin Care",
                stockQuantity: 40,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1571875257727-256c39da42af?w=800"
                ],
                sku: "SKIN-RETI-001",
                weight: 1.7,
                tags: ["retinol", "night cream", "anti-aging", "wrinkles"]
            ),
            
            // Body Care Products
            Product(
                name: "Whipped Body Butter",
                description: "Luxuriously whipped body butter with shea and cocoa butter. Deeply nourishes and leaves skin silky smooth.",
                price: 29.99,
                category: "Body Care",
                stockQuantity: 65,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=800"
                ],
                sku: "BODY-WHIP-001",
                weight: 8.0,
                tags: ["body butter", "moisturizer", "shea butter"]
            ),
            Product(
                name: "Sugar Scrub Exfoliant",
                description: "Natural sugar scrub with coconut oil and vanilla. Gently exfoliates and moisturizes for baby-soft skin.",
                price: 26.99,
                salePrice: 21.99,
                category: "Body Care",
                stockQuantity: 48,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=800"
                ],
                sku: "BODY-SCRU-001",
                weight: 12.0,
                tags: ["scrub", "exfoliant", "sugar", "coconut"]
            ),
            Product(
                name: "Nourishing Hand Cream",
                description: "Fast-absorbing hand cream with shea butter and vitamin E. Non-greasy formula protects and softens hands.",
                price: 16.99,
                category: "Body Care",
                stockQuantity: 80,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800"
                ],
                sku: "BODY-HAND-001",
                weight: 3.0,
                tags: ["hand cream", "moisturizer", "fast absorbing"]
            ),
            
            // Gift Sets
            Product(
                name: "Complete Hair Care Set",
                description: "Everything you need for healthy hair: coconut oil, shea butter mask, and argan leave-in conditioner.",
                price: 79.99,
                salePrice: 64.99,
                category: "Gift Sets",
                stockQuantity: 25,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=800"
                ],
                sku: "GIFT-HAIR-001",
                weight: 24.5,
                tags: ["gift set", "hair care", "bundle", "value"]
            ),
            Product(
                name: "Skin Care Essentials Kit",
                description: "Daily skin care routine in one box: cleanser, vitamin C serum, and hyaluronic moisturizer.",
                price: 99.99,
                salePrice: 84.99,
                category: "Gift Sets",
                stockQuantity: 20,
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=800"
                ],
                sku: "GIFT-SKIN-001",
                weight: 8.0,
                tags: ["gift set", "skin care", "bundle", "routine"]
            ),
            
            // Limited Edition / Out of Stock Example
            Product(
                name: "Limited Edition Rose Gold Set",
                description: "Exclusive rose gold collection with premium ingredients. Contains face oil, body butter, and lip balm.",
                price: 129.99,
                category: "Gift Sets",
                stockQuantity: 0,  // Out of stock
                isActive: true,
                imageURLs: [
                    "https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=800"
                ],
                sku: "GIFT-ROSE-001",
                weight: 10.0,
                tags: ["limited edition", "rose gold", "premium", "gift"]
            ),
            
            // Deactivated Product Example
            Product(
                name: "Winter Wonderland Body Oil",
                description: "Seasonal body oil with cinnamon and vanilla scents. Only available during winter months.",
                price: 34.99,
                category: "Body Care",
                stockQuantity: 15,
                isActive: false,  // Seasonal - deactivated
                imageURLs: [
                    "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800"
                ],
                sku: "BODY-WINT-001",
                weight: 6.0,
                tags: ["seasonal", "winter", "body oil", "limited"]
            )
        ]
        
        context.console.print("💾 Saving \(sampleProducts.count) products...")
        
        for product in sampleProducts {
            try await product.save(on: context.application.db)
            let status = product.isActive ? "✅" : "⏸️ "
            let sale = product.salePrice != nil ? " (SALE)" : ""
            context.console.print("  \(status) \(product.name) - $\(product.price)\(sale)")
        }
        
        context.console.print("✅ Successfully seeded \(sampleProducts.count) products!")
        context.console.print("")
        context.console.print("📊 Summary:")
        
        let total = try await Product.query(on: context.application.db).count()
        let active = try await Product.query(on: context.application.db)
            .filter(\.$isActive == true)
            .count()
        let onSale = sampleProducts.filter { $0.salePrice != nil }.count
        
        context.console.print("  Total products: \(total)")
        context.console.print("  Active products: \(active)")
        context.console.print("  Products on sale: \(onSale)")
        context.console.print("")
        context.console.print("🎉 Done! You can now browse products at /api/products")
    }
}

// MARK: - Register Command
extension Application {
    func registerProductSeeder() {
        commands.use(SeedProductsCommand() as! (any AnyCommand), as: "seed:products")
    }
}
