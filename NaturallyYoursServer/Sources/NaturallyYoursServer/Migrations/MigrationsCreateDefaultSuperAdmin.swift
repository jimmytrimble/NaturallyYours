import Fluent
import Vapor

/// Creates a default super admin account for initial setup
/// Only run this once! Delete or comment out after creating your first admin.
struct CreateDefaultSuperAdmin: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Check if any admins exist
        let existingAdmins = try await Admin.query(on: database).count()
        
        // Only create default admin if no admins exist
        guard existingAdmins == 0 else {
            return
        }
        
        let passwordHash = try Bcrypt.hash("ChangeMe123!")
        let superAdmin = Admin(
            name: "Super Admin",
            email: "admin@naturallyyours.com",
            passwordHash: passwordHash,
            role: .superAdmin
        )
        
        try await superAdmin.save(on: database)
        
        print("✅ Default super admin created!")
        print("📧 Email: admin@naturallyyours.com")
        print("🔑 Password: ChangeMe123!")
        print("⚠️  IMPORTANT: Change this password immediately after first login!")
    }
    
    func revert(on database: any Database) async throws {
        // Find and delete the default admin
        if let defaultAdmin = try await Admin.query(on: database)
            .filter(\.$email == "admin@naturallyyours.com")
            .first() {
            try await defaultAdmin.delete(on: database)
        }
    }
}
