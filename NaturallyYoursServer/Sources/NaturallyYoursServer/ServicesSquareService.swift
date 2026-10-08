import Vapor

/// Which Square environment to talk to.
enum SquareEnvironment: String, Sendable {
    case sandbox
    case production
}

/// Square API configuration, loaded from environment variables (see `.env`).
struct SquareConfiguration: Sendable {
    let accessToken: String
    let applicationID: String
    let locationID: String
    let environment: SquareEnvironment

    /// The Square Connect API version header value.
    static let apiVersion = "2025-01-23"

    var apiBaseURL: String {
        switch environment {
        case .production: return "https://connect.squareup.com"
        case .sandbox:    return "https://connect.squareupsandbox.com"
        }
    }

    /// Loads configuration from the environment. Returns `nil` if required keys are missing.
    static func fromEnvironment() -> SquareConfiguration? {
        guard
            let accessToken = Environment.get("SQUARE_ACCESS_TOKEN"), !accessToken.isEmpty,
            let applicationID = Environment.get("SQUARE_APPLICATION_ID"), !applicationID.isEmpty,
            let locationID = Environment.get("SQUARE_LOCATION_ID"), !locationID.isEmpty
        else {
            return nil
        }
        let env = SquareEnvironment(rawValue: Environment.get("SQUARE_ENVIRONMENT") ?? "sandbox") ?? .sandbox
        return SquareConfiguration(
            accessToken: accessToken,
            applicationID: applicationID,
            locationID: locationID,
            environment: env
        )
    }
}

/// Result of a successful Square payment.
struct SquarePayment: Content {
    let id: String
    let status: String
    let receiptURL: String?
}

/// Thin wrapper around the Square Payments API using Vapor's HTTP client.
struct SquareService: Sendable {
    let config: SquareConfiguration
    let client: any Client
    let logger: Logger

    /// Charges a payment source (the card nonce / token produced by the In-App Payments SDK).
    ///
    /// - Parameters:
    ///   - sourceID: The payment token from the client SDK.
    ///   - amountCents: Total to charge, in the smallest currency unit (cents).
    ///   - currency: ISO currency code (default USD).
    ///   - idempotencyKey: Unique key so retries don't double-charge.
    ///   - referenceID: Our internal order reference (shows in the Square dashboard).
    ///   - note: Optional human-readable note.
    func createPayment(
        sourceID: String,
        amountCents: Int,
        currency: String = "USD",
        idempotencyKey: String,
        referenceID: String? = nil,
        note: String? = nil
    ) async throws -> SquarePayment {
        let uri = URI(string: "\(config.apiBaseURL)/v2/payments")

        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(config.accessToken)")
        headers.add(name: "Square-Version", value: SquareConfiguration.apiVersion)
        headers.contentType = .json

        let body = CreatePaymentBody(
            sourceID: sourceID,
            idempotencyKey: idempotencyKey,
            amountMoney: .init(amount: amountCents, currency: currency),
            locationID: config.locationID,
            referenceID: referenceID,
            note: note,
            autocomplete: true
        )

        let response = try await client.post(uri, headers: headers) { req in
            try req.content.encode(body, as: .json)
        }

        guard response.status == .ok || response.status == .created else {
            // Surface Square's error detail to the caller/logs.
            let message = (try? response.content.decode(SquareErrorResponse.self))?
                .errors.first?.detail ?? "Square payment failed (HTTP \(response.status.code))"
            logger.error("Square payment error: \(message)")
            throw Abort(.badGateway, reason: "Payment failed: \(message)")
        }

        let payload = try response.content.decode(CreatePaymentResponse.self)
        let payment = payload.payment
        logger.info("Square payment \(payment.id) status=\(payment.status)")
        return SquarePayment(id: payment.id, status: payment.status, receiptURL: payment.receiptURL)
    }

    /// Whether a Square payment status represents a successful capture.
    static func isSuccessful(status: String) -> Bool {
        status == "COMPLETED" || status == "APPROVED"
    }
}

// MARK: - Square request/response wire types

private struct CreatePaymentBody: Content {
    let sourceID: String
    let idempotencyKey: String
    let amountMoney: Money
    let locationID: String
    let referenceID: String?
    let note: String?
    let autocomplete: Bool

    struct Money: Content {
        let amount: Int
        let currency: String
    }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case idempotencyKey = "idempotency_key"
        case amountMoney = "amount_money"
        case locationID = "location_id"
        case referenceID = "reference_id"
        case note
        case autocomplete
    }
}

private struct CreatePaymentResponse: Content {
    let payment: Payment

    struct Payment: Content {
        let id: String
        let status: String
        let receiptURL: String?

        enum CodingKeys: String, CodingKey {
            case id
            case status
            case receiptURL = "receipt_url"
        }
    }
}

private struct SquareErrorResponse: Content {
    let errors: [SquareError]

    struct SquareError: Content {
        let category: String?
        let code: String?
        let detail: String?
    }
}
