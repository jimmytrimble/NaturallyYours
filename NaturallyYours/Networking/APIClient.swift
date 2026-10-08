import Foundation

/// Errors surfaced by the networking layer.
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request address was invalid."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case let .http(status, message):
            return message ?? "The server returned an error (\(status))."
        case .decoding:
            return "We couldn't read the server's response."
        case let .transport(error):
            return error.localizedDescription
        }
    }

    /// True when the failure was a 401 (not signed in).
    var isUnauthorized: Bool {
        if case let .http(status, _) = self { return status == 401 }
        return false
    }
}

/// Shape of the error body Vapor returns: `{ "error": true, "reason": "…" }`.
private struct ServerError: Decodable {
    let reason: String?
}

/// A shared, cookie-aware HTTP client for talking to the Naturally Yours server.
///
/// The server authenticates with session cookies, so this client uses the shared
/// `HTTPCookieStorage`. `AuthService` uses the same shared cookie storage, which
/// means a session established at login is automatically sent on every request
/// made through this client (cart, favorites, orders, messaging, checkout).
///
/// The Vapor server encodes JSON with Foundation's default strategies (camelCase
/// keys, `deferredToDate` dates), so a vanilla `JSONEncoder`/`JSONDecoder` here
/// round-trips correctly — no key or date strategy overrides are needed.
final class APIClient {
    static let shared = APIClient()

    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: String = AppConfiguration.apiBaseURL) {
        self.baseURL = baseURL

        // Vapor emits camelCase keys and ISO8601 date strings (e.g. "2026-10-08T19:05:55Z"),
        // so keep key names as-is and match the date strategy on both sides.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = .shared
        config.timeoutIntervalForRequest = AppConfiguration.requestTimeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public request API

    /// Performs a GET request and decodes the response.
    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let request = try buildRequest(method: "GET", path: path, query: query, bodyData: nil)
        return try await perform(request)
    }

    /// Performs a request with a JSON body and decodes the response.
    @discardableResult
    func send<T: Decodable, Body: Encodable>(
        _ method: String,
        _ path: String,
        body: Body,
        query: [URLQueryItem] = []
    ) async throws -> T {
        let request = try buildRequest(method: method, path: path, query: query, bodyData: encode(body))
        return try await perform(request)
    }

    /// Performs a request with no body and decodes the response.
    @discardableResult
    func send<T: Decodable>(_ method: String, _ path: String, query: [URLQueryItem] = []) async throws -> T {
        let request = try buildRequest(method: method, path: path, query: query, bodyData: nil)
        return try await perform(request)
    }

    /// Performs a request with a JSON body that returns no body (204 / empty 200).
    func sendNoContent<Body: Encodable>(
        _ method: String,
        _ path: String,
        body: Body,
        query: [URLQueryItem] = []
    ) async throws {
        let request = try buildRequest(method: method, path: path, query: query, bodyData: encode(body))
        _ = try await performRaw(request)
    }

    /// Performs a request with no body that returns no body (204 / empty 200).
    func sendNoContent(_ method: String, _ path: String, query: [URLQueryItem] = []) async throws {
        let request = try buildRequest(method: method, path: path, query: query, bodyData: nil)
        _ = try await performRaw(request)
    }

    // MARK: - Image URL helper

    /// Resolves a product image URL. Absolute URLs (Shopify CDN, etc.) are used as-is;
    /// server-relative paths (e.g. `/uploads/products/x.jpg`) get the API base prepended.
    func imageURL(for raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        let separator = raw.hasPrefix("/") ? "" : "/"
        return URL(string: baseURL + separator + raw)
    }

    // MARK: - Internals

    private func encode<Body: Encodable>(_ body: Body) throws -> Data {
        do {
            return try encoder.encode(body)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func buildRequest(
        method: String,
        path: String,
        query: [URLQueryItem],
        bodyData: Data?
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }
        return request
    }

    private func performRaw(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let reason = (try? decoder.decode(ServerError.self, from: data))?.reason
            throw APIError.http(status: http.statusCode, message: reason)
        }

        if AppConfiguration.enableNetworkLogging {
            print("[API] \(request.httpMethod ?? "?") \(request.url?.path ?? "") → \(http.statusCode)")
        }

        return data
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await performRaw(request)

        // Allow empty-body successes to decode into Optional / empty types gracefully.
        if data.isEmpty, let empty = EmptyBody() as? T {
            return empty
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

/// Placeholder decodable for endpoints that may return an empty success body.
struct EmptyBody: Decodable {}
