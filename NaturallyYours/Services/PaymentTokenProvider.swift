import Foundation

/// Abstraction over card tokenization so checkout doesn't depend directly on a
/// specific payments SDK. The server's `/api/checkout` needs a Square payment
/// `sourceID` (a single-use card token).
///
/// Production path: implement this with the **Square In-App Payments SDK**
/// (add via SPM/CocoaPods), present the SDK's card entry UI, and return the
/// resulting nonce/token. Wire `SQUARE_APPLICATION_ID` + `SQUARE_LOCATION_ID`
/// (sandbox) into the client.
///
/// Until the SDK is integrated, `SandboxPaymentTokenProvider` returns Square's
/// well-known **sandbox** test nonce so the full checkout → order flow can be
/// exercised end-to-end against a sandbox-configured server.
protocol PaymentTokenProvider {
    /// Returns a single-use payment token for the given amount (in dollars).
    func cardToken(amount: Double) async throws -> String
}

enum PaymentError: LocalizedError {
    case cancelled
    case tokenizationFailed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Payment was cancelled."
        case let .tokenizationFailed(message):
            return message
        }
    }
}

/// Placeholder provider that returns Square's sandbox test nonce. Replace with a
/// real Square In-App Payments SDK implementation before going live.
struct SandboxPaymentTokenProvider: PaymentTokenProvider {
    func cardToken(amount: Double) async throws -> String {
        // Square sandbox: `cnon:card-nonce-ok` always approves. See Square docs:
        // https://developer.squareup.com/docs/devtools/sandbox/payments
        "cnon:card-nonce-ok"
    }
}
