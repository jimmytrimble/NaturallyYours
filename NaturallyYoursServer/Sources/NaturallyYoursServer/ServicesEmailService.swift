import Vapor
import NIOCore
import NIOPosix
import NIOSSL

/// SMTP configuration for the Zoho support mailbox, loaded from environment variables.
/// Returns `nil` (email disabled, no-op) when the required keys are absent.
struct EmailConfiguration: Sendable {
    let host: String
    let port: Int
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
        let port = Int(Environment.get("ZOHO_SMTP_PORT") ?? "465") ?? 465
        let username = Environment.get("ZOHO_SMTP_USER") ?? support
        let fromName = Environment.get("SUPPORT_FROM_NAME") ?? "Naturally Yours Support"
        return EmailConfiguration(
            host: host, port: port, username: username,
            password: password, fromName: fromName, fromEmail: support
        )
    }
}

enum EmailError: Error, CustomStringConvertible {
    case unexpectedResponse(expected: String, got: String)

    var description: String {
        switch self {
        case let .unexpectedResponse(expected, got):
            return "SMTP expected \(expected) but got: \(got.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}

/// Minimal SMTP client over SwiftNIO with implicit TLS (port 465), using the same
/// NIOSSL stack Vapor relies on. Sends transactional email from the support mailbox.
struct EmailService: Sendable {
    let config: EmailConfiguration
    let logger: Logger

    func send(to email: String, name: String, subject: String, body: String, replyTo: String? = nil) async throws {
        let group = NIOSingletons.posixEventLoopGroup
        let sslContext = try NIOSSLContext(configuration: .makeClientConfiguration())
        let serverHostname = config.host
        let handler = SMTPResponseHandler()

        let channel = try await ClientBootstrap(group: group)
            .connectTimeout(.seconds(15))
            .channelInitializer { channel in
                do {
                    let ssl = try NIOSSLClientHandler(context: sslContext, serverHostname: serverHostname)
                    return channel.pipeline.addHandlers([ssl, handler])
                } catch {
                    return channel.eventLoop.makeFailedFuture(error)
                }
            }
            .connect(host: config.host, port: config.port)
            .get()

        func expect(_ code: String) async throws {
            let response = try await handler.next(on: channel.eventLoop).get()
            guard response.hasPrefix(code) else {
                throw EmailError.unexpectedResponse(expected: code, got: response)
            }
        }

        func write(_ line: String) async throws {
            var buffer = channel.allocator.buffer(capacity: line.utf8.count + 2)
            buffer.writeString(line)
            buffer.writeString("\r\n")
            try await channel.writeAndFlush(buffer).get()
        }

        func b64(_ s: String) -> String { Data(s.utf8).base64EncodedString() }

        do {
            try await expect("220")
            try await write("EHLO naturallyyours.app");  try await expect("250")
            try await write("AUTH LOGIN");                try await expect("334")
            try await write(b64(config.username));        try await expect("334")
            try await write(b64(config.password));        try await expect("235")
            try await write("MAIL FROM:<\(config.fromEmail)>"); try await expect("250")
            try await write("RCPT TO:<\(email)>");        try await expect("250")
            try await write("DATA");                      try await expect("354")
            try await write(Self.message(config: config, toName: name, toEmail: email,
                                         subject: subject, body: body, replyTo: replyTo))
            try await expect("250")
            try await write("QUIT")
        }
        try? await channel.close()
    }

    /// Builds an RFC 5322 message ending with the SMTP data terminator (CRLF "." CRLF).
    private static func message(config: EmailConfiguration, toName: String, toEmail: String,
                                subject: String, body: String, replyTo: String?) -> String {
        let date = ISO8601DateFormatter().string(from: Date())
        var headers = [
            "From: \(config.fromName) <\(config.fromEmail)>",
            "To: \(toName) <\(toEmail)>",
            "Subject: \(subject)",
            "Date: \(date)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=UTF-8"
        ]
        if let replyTo { headers.append("Reply-To: \(replyTo)") }

        // Dot-stuff any line beginning with "." per SMTP, and normalize newlines to CRLF.
        let normalizedBody = body
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.hasPrefix(".") ? "." + $0 : String($0) }
            .joined(separator: "\r\n")

        return headers.joined(separator: "\r\n") + "\r\n\r\n" + normalizedBody + "\r\n."
    }
}

/// Collects complete SMTP responses (handling multi-line `250-`/`250 ` replies) and
/// hands them to awaiting callers one at a time.
private final class SMTPResponseHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer

    private var accumulated = ""
    private var ready: [String] = []
    private var waiter: EventLoopPromise<String>?

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        accumulated += buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) ?? ""
        while let response = takeCompleteResponse() {
            if let waiter {
                self.waiter = nil
                waiter.succeed(response)
            } else {
                ready.append(response)
            }
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        waiter?.fail(error)
        waiter = nil
        context.close(promise: nil)
    }

    /// Returns the next complete SMTP response, awaiting more data if necessary.
    func next(on eventLoop: EventLoop) -> EventLoopFuture<String> {
        eventLoop.flatSubmit {
            if !self.ready.isEmpty {
                return eventLoop.makeSucceededFuture(self.ready.removeFirst())
            }
            let promise = eventLoop.makePromise(of: String.self)
            self.waiter = promise
            return promise.futureResult
        }
    }

    /// Extracts one complete response from `accumulated` if present. A response ends on
    /// the first fully-received line whose 4th character is a space (not `-`).
    private func takeCompleteResponse() -> String? {
        let lines = accumulated.components(separatedBy: "\r\n")
        // The last element is a trailing partial line (empty if data ended on CRLF);
        // only consider lines before it as fully received.
        guard lines.count >= 2 else { return nil }
        for index in 0..<(lines.count - 1) {
            let line = lines[index]
            if line.count >= 4 {
                let marker = line[line.index(line.startIndex, offsetBy: 3)]
                if marker == " " {
                    let response = lines[0...index].joined(separator: "\r\n")
                    let remaining = lines[(index + 1)...].joined(separator: "\r\n")
                    accumulated = remaining
                    return response
                }
            }
        }
        return nil
    }
}
