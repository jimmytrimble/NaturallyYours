import NIOSSL
import Fluent
import FluentSQLiteDriver
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Bind to the port Render provides via $PORT (and all interfaces) in production.
    app.http.server.configuration.hostname = "0.0.0.0"
    if let port = Environment.get("PORT").flatMap(Int.init) {
        app.http.server.configuration.port = port
    }

    // Serve files from the /Public folder (admin-uploaded product images live here).
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure database: PostgreSQL in production (Render sets DATABASE_URL),
    // falling back to a local SQLite file for development.
    if let databaseURL = Environment.get("DATABASE_URL") {
        try configurePostgres(app, urlString: databaseURL)
        app.logger.info("Using PostgreSQL database")
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
        app.logger.info("Using local SQLite database")
    }

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

    // Local testing convenience admin (test@account.com / 123456789, super admin).
    // Idempotent; remove before shipping to production.
    app.migrations.add(CreateTestAdmin())
    
    // E-commerce migrations
    app.migrations.add(CreateProduct())
    app.migrations.add(AddProductFeatured())
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

/// Configures the PostgreSQL database from a connection URL (e.g. Render's DATABASE_URL).
///
/// Uses `.prefer` TLS so it works with both Render's internal connection (plaintext)
/// and external connections (TLS), with certificate verification disabled to avoid
/// issues with Render's managed-Postgres certificates.
private func configurePostgres(_ app: Application, urlString: String) throws {
    guard let url = URL(string: urlString), let hostname = url.host else {
        throw Abort(.internalServerError, reason: "Invalid DATABASE_URL")
    }

    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    let sslContext = try NIOSSLContext(configuration: tls)

    let database = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path

    let configuration = SQLPostgresConfiguration(
        hostname: hostname,
        port: url.port ?? SQLPostgresConfiguration.ianaPortNumber,
        username: url.user ?? "",
        password: url.password,
        database: database.isEmpty ? nil : database,
        tls: .prefer(sslContext)
    )

    app.databases.use(.postgres(configuration: configuration), as: .psql)
}
