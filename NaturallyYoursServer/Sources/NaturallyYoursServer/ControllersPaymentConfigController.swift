import Vapor

/// Exposes the *publishable* Square client configuration (application ID + location ID)
/// so the iOS app can initialize the Square Web Payments SDK. These values are not
/// secret — only the access token (kept server-side) is.
struct PaymentConfigController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("api", "payments").get("config", use: config)
    }

    func config(req: Request) async throws -> PaymentConfigDTO {
        guard let cfg = SquareConfiguration.fromEnvironment() else {
            throw Abort(.serviceUnavailable, reason: "Payments are not configured")
        }
        return PaymentConfigDTO(
            applicationID: cfg.applicationID,
            locationID: cfg.locationID,
            environment: cfg.environment.rawValue
        )
    }
}

struct PaymentConfigDTO: Content {
    let applicationID: String
    let locationID: String
    let environment: String
}
