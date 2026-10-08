import Fluent
import Vapor
import struct Foundation.UUID
import struct Foundation.Date

/// Whether a conversation is still active or has been resolved.
enum ConversationStatus: String, Codable, Sendable, CaseIterable {
    case open
    case closed
}

/// Who sent a given message.
enum MessageSenderType: String, Codable, Sendable {
    case customer
    case admin
}

/// A support/contact conversation between a customer (registered or guest) and
/// the admin team. Acts as a shared inbox: all admins can see and reply.
final class Conversation: Model, @unchecked Sendable {
    static let schema = "conversations"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "subject")
    var subject: String

    /// Owning customer — null for guests.
    @OptionalParent(key: "user_id")
    var user: User?

    /// Guest retrieval key (mirrors the cart session pattern) so guests can see replies.
    @OptionalField(key: "session_id")
    var sessionID: String?

    @Field(key: "customer_name")
    var customerName: String

    @Field(key: "customer_email")
    var customerEmail: String

    @Field(key: "status")
    var status: ConversationStatus

    /// The admin currently handling this conversation (optional / first responder).
    @OptionalParent(key: "assigned_admin_id")
    var assignedAdmin: Admin?

    @Field(key: "has_unread_for_admin")
    var hasUnreadForAdmin: Bool

    @Field(key: "has_unread_for_customer")
    var hasUnreadForCustomer: Bool

    @OptionalField(key: "last_message_at")
    var lastMessageAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$conversation)
    var messages: [Message]

    init() { }

    init(
        id: UUID? = nil,
        subject: String,
        userID: UUID? = nil,
        sessionID: String? = nil,
        customerName: String,
        customerEmail: String,
        status: ConversationStatus = .open
    ) {
        self.id = id
        self.subject = subject
        self.$user.id = userID
        self.sessionID = sessionID
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.status = status
        self.$assignedAdmin.id = nil
        self.hasUnreadForAdmin = true
        self.hasUnreadForCustomer = false
    }
}

/// A single message within a conversation.
final class Message: Model, @unchecked Sendable {
    static let schema = "messages"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "conversation_id")
    var conversation: Conversation

    @Field(key: "sender_type")
    var senderType: MessageSenderType

    /// Denormalized display name of the sender at send time.
    @Field(key: "sender_name")
    var senderName: String

    @OptionalParent(key: "sender_user_id")
    var senderUser: User?

    @OptionalParent(key: "sender_admin_id")
    var senderAdmin: Admin?

    @Field(key: "body")
    var body: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        conversationID: UUID,
        senderType: MessageSenderType,
        senderName: String,
        senderUserID: UUID? = nil,
        senderAdminID: UUID? = nil,
        body: String
    ) {
        self.id = id
        self.$conversation.id = conversationID
        self.senderType = senderType
        self.senderName = senderName
        self.$senderUser.id = senderUserID
        self.$senderAdmin.id = senderAdminID
        self.body = body
    }
}

// MARK: - DTOs

struct MessageDTO: Content {
    let id: UUID?
    let senderType: MessageSenderType
    let senderName: String
    let body: String
    let createdAt: Date?
}

extension Message {
    func toDTO() -> MessageDTO {
        .init(
            id: self.id,
            senderType: self.senderType,
            senderName: self.senderName,
            body: self.body,
            createdAt: self.createdAt
        )
    }
}

struct ConversationDTO: Content {
    let id: UUID?
    let subject: String
    let customerName: String
    let customerEmail: String
    let status: ConversationStatus
    let hasUnreadForAdmin: Bool
    let hasUnreadForCustomer: Bool
    let lastMessageAt: Date?
    let createdAt: Date?
    /// Included when a single conversation is fetched; empty in list views.
    let messages: [MessageDTO]
}

extension Conversation {
    func toDTO(includeMessages: Bool = false) -> ConversationDTO {
        .init(
            id: self.id,
            subject: self.subject,
            customerName: self.customerName,
            customerEmail: self.customerEmail,
            status: self.status,
            hasUnreadForAdmin: self.hasUnreadForAdmin,
            hasUnreadForCustomer: self.hasUnreadForCustomer,
            lastMessageAt: self.lastMessageAt,
            createdAt: self.createdAt,
            messages: includeMessages ? (self.$messages.value ?? []).map { $0.toDTO() } : []
        )
    }
}
