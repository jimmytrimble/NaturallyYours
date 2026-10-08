import Vapor
import Fluent

/// Helper commands for development and testing
/// To run: swift run NaturallyYoursServer seed
struct SeedCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Flag(name: "users", help: "Seed test users")
        var users: Bool
        
        @Flag(name: "admins", help: "Seed test admins")
        var admins: Bool
    }
    
    var help: String {
        "Seeds the database with test data"
    }
    
    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application
        
        if signature.users {
            try await seedUsers(on: app.db)
            context.console.success("✅ Seeded test users")
        }
        
        if signature.admins {
            try await seedAdmins(on: app.db)
            context.console.success("✅ Seeded test admins")
        }
        
        if !signature.users && !signature.admins {
            context.console.info("ℹ️  Use --users or --admins flags to seed specific data")
            context.console.info("Example: swift run NaturallyYoursServer seed --users --admins")
        }
    }
    
    // MARK: - Seed Users
    
    private func seedUsers(on db: any Database) async throws {
        let testUsers = [
            ("Alice Johnson", "alice@example.com", "Password123"),
            ("Bob Smith", "bob@example.com", "Password123"),
            ("Carol White", "carol@example.com", "Password123"),
        ]
        
        for (name, email, password) in testUsers {
            // Check if user already exists
            let existingUser = try await User.query(on: db)
                .filter(\.$email == email)
                .first()
            
            if existingUser == nil {
                let passwordHash = try Bcrypt.hash(password)
                let user = User(name: name, email: email, passwordHash: passwordHash)
                try await user.save(on: db)
            }
        }
    }
    
    // MARK: - Seed Admins
    
    private func seedAdmins(on db: any Database) async throws {
        let testAdmins: [(String, String, String, AdminRole)] = [
            ("Test Super Admin", "superadmin@test.com", "Admin123!", .superAdmin),
            ("Test Moderator", "moderator@test.com", "Admin123!", .moderator),
            ("Test Support", "support@test.com", "Admin123!", .support),
        ]
        
        for (name, email, password, role) in testAdmins {
            // Check if admin already exists
            let existingAdmin = try await Admin.query(on: db)
                .filter(\.$email == email)
                .first()
            
            if existingAdmin == nil {
                let passwordHash = try Bcrypt.hash(password)
                let admin = Admin(name: name, email: email, passwordHash: passwordHash, role: role)
                try await admin.save(on: db)
            }
        }
    }
}

// MARK: - Register Command

extension Application {
    func registerCommands() {
        commands.use(SeedCommand() as! (any AnyCommand), as: "seed")
    }
}
