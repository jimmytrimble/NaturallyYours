import Fluent
import Vapor

/// Seeds a convenience test admin for local end-to-end testing.
///
/// Credentials: test@account.com / 123456789 (super admin).
/// Idempotent — does nothing if an admin with this email already exists.
/// ⚠️ For local/testing only; do not ship this to production.
struct CreateTestAdmin: AsyncMigration {
    private static let email = "test@account.com"

    func prepare(on database: any Database) async throws {
        let existing = try await Admin.query(on: database)
            .filter(\.$email == Self.email)
            .first()
        guard existing == nil else { return }

        let admin = Admin(
            name: "Test Account",
            email: Self.email,
            passwordHash: try Bcrypt.hash("123456789"),
            role: .superAdmin
        )
        try await admin.save(on: database)

        print("✅ Test admin created — email: \(Self.email) / password: 123456789 (super admin)")
    }

    func revert(on database: any Database) async throws {
        try await Admin.query(on: database)
            .filter(\.$email == Self.email)
            .delete()
    }
}
