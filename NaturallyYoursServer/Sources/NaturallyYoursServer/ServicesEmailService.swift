import Vapor
import SwiftSMTP

/// SMTP configuration for the Zoho support mailbox, loaded from environment variables.
/// Returns `nil` (email disabled, no-op) when the required keys are absent so the app
/// runs fine without credentials.
struct EmailConfiguration: Sendable {
    let host: String
    let port: Int32
    let username: String
    let password: String
    let fromName: String
    let fromEmail: String

    static func fromEnvironment() -> EmailConfiguration? {
        guard
            let password = Environment.get("ZOHO_APP_PASSWORD"), !password.isEmpty,
            let support = Environment.get("SUPPORT_EMAIL"), !support.isEmpty
        else {
            return nil
        }
        let host = Environment.get("ZOHO_SMTP_HOST") ?? "smtp.zoho.com"
        let port = Int32(Environment.get("ZOHO_SMTP_PORT") ?? "465") ?? 465
        let username = Environment.get("ZOHO_SMTP_USER") ?? support
        let fromName = Environment.get("SUPPORT_FROM_NAME") ?? "Naturally Yours Support"
        return EmailConfiguration(
            host: host, port: port, username: username,
            password: password, fromName: fromName, fromEmail: support
        )
    }
}

/// Sends transactional emails from the support mailbox via Zoho SMTP.
struct EmailService: Sendable {
    let config: EmailConfiguration
    let logger: Logger

    /// Sends a plain-text email from the support address to a customer.
    func send(to email: String, name: String, subject: String, body: String) async throws {
        let smtp = SMTP(
            hostname: config.host,
            email: config.username,
            password: config.password,
            port: config.port,
            tlsMode: config.port == 587 ? .requireSTARTTLS : .requireTLS
        )
        let from = Mail.User(name: config.fromName, email: config.fromEmail)
        let to = Mail.User(name: name, email: email)
        let mail = Mail(from: from, to: [to], subject: subject, text: body)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            smtp.send(mail) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
