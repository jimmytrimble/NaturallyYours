import Foundation
import Observation

/// Customer-side in-app messaging via `/api/contact` and `/api/conversations`.
@MainActor
@Observable
final class MessagingService {
    var conversations: [ConversationDTO] = []
    var isLoading = false
    var errorMessage: String?

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    /// Loads the current customer's conversations from `GET /api/conversations`.
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        do {
            conversations = try await client.get("/api/conversations")
        } catch let error as APIError where error.isUnauthorized {
            conversations = []
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    /// Starts a new conversation via `POST /api/contact`. For guests, `name` and
    /// `email` are required; for signed-in users they are taken from the account.
    @discardableResult
    func startConversation(
        subject: String,
        message: String,
        name: String? = nil,
        email: String? = nil
    ) async throws -> ConversationDTO {
        let body = StartConversationRequest(subject: subject, message: message, name: name, email: email)
        let conversation: ConversationDTO = try await client.send("POST", "/api/contact", body: body)
        return conversation
    }

    /// Fetches a single conversation (with its messages) via
    /// `GET /api/conversations/:id`.
    func conversation(id: UUID) async throws -> ConversationDTO {
        try await client.get("/api/conversations/\(id.uuidString)")
    }

    /// Posts a customer reply via `POST /api/conversations/:id/messages`.
    @discardableResult
    func reply(conversationID: UUID, message: String) async throws -> ConversationDTO {
        let body = ConversationReplyRequest(message: message)
        return try await client.send("POST", "/api/conversations/\(conversationID.uuidString)/messages", body: body)
    }
}
