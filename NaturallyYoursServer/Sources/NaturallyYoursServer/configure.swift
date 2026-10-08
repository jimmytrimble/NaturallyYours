import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Serve files from the /Public folder (admin-uploaded product images live here).
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configure sessions
    app.sessions.use(.fluent)
    app.middleware.use(app.sessions.middleware)
    
    // Configure migrations
    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAdmin())
    
    // Uncomment ONLY for initial setup to create first super admin.
    // Already run once — a super admin exists (admin@naturallyyours.com / ChangeMe123!),
    // so this stays disabled. The migration is idempotent (no-op if any admin exists).
//     app.migrations.add(CreateDefaultSuperAdmin())
//
    app.migrations.add(CreateTodo())
    
    // E-commerce migrations
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateCart())
    app.migrations.add(CreateCartItem())
    app.migrations.add(CreateFavorite())
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateMessaging())
    
    // Auto-run migrations (remove in production, use vapor run migrate)
     try await app.autoMigrate()

    // Seed the catalog from SeedData/products.csv on first run (empty products table).
    try await ProductImporter.seedIfNeeded(app)

    // Register custom commands
    app.registerProductSeeder()

    // register routes
    try routes(app)
}
