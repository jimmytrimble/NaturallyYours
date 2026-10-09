import Vapor
import Fluent

/// In-app contact / messaging system. Customers (registered or guest) start
/// conversations and reply; all admins share an inbox and can respond.
struct MessagingController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Customer side. sessionAuthenticator attaches a user if logged in but
        // does not require it, so guests can message too (tracked via session).
        let api = routes.grouped("api").grouped(User.sessionAuthenticator())
        api.post("contact", use: startConversation)
        api.get("conversations", use: listMyConversations)
        api.get("conversations", ":conversationID", use: getMyConversation)
        api.post("conversations", ":conversationID", "messages", use: customerReply)

        // Admin shared inbox — any authenticated admin (including support) can view/reply.
        let admin = routes.grouped("api", "admin", "conversations")
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())
        admin.get(use: adminListConversations)
        admin.get(":conversationID", use: adminGetConversation)
        admin.post(":conversationID", "messages", use: adminReply)
        admin.patch(":conversationID", use: adminUpdateConversation)
    }

    // MARK: - Customer

    func startConversation(req: Request) async throws -> ConversationDTO {
        struct StartRequest: Content {
            let subject: String
            let message: String
            let name: String?
            let email: String?
        }
        let data = try req.content.decode(StartRequest.self)

        guard !data.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Message cannot be empty")
        }

        let user = req.auth.get(User.self)
        let name: String
        let email: String
        if let user {
            name = user.name
            email = user.email
        } else {
            guard let n = data.name, !n.isEmpty, let e = data.email, e.contains("@") else {
                throw Abort(.badRequest, reason: "Name and a valid email are required")
            }
            name = n
            email = e
        }

        let sessionID = user == nil ? getOrCreateSessionID(req: req) : nil

        let conversation = Conversation(
            subject: data.subject.isEmpty ? "New inquiry" : data.subject,
            userID: user?.id,
            sessionID: sessionID,
            customerName: name,
            customerEmail: email
        )
        conversation.lastMessageAt = Date()
        try await conversation.save(on: req.db)

        let message = Message(
            conversationID: try conversation.requireID(),
            senderType: .customer,
            senderName: name,
            senderUserID: user?.id,
            body: data.message
        )
        try await message.save(on: req.db)

        req.logger.info("New conversation \(conversation.id?.uuidString ?? "?") from \(email)")

        try await loadMessagesSorted(conversation, on: req.db)
        return conversation.toDTO(includeMessages: true)
    }

    func listMyConversations(req: Request) async throws -> [ConversationDTO] {
        let conversations = try await myConversationsQuery(req: req)
            .sort(\.$lastMessageAt, .descending)
            .all()
        return conversations.map { $0.toDTO() }
    }

    func getMyConversation(req: Request) async throws -> ConversationDTO {
        let conversation = try await requireMyConversation(req: req)
        try await loadMessagesSorted(conversation, on: req.db)

        // Customer has now seen the replies.
        if conversation.hasUnreadForCustomer {
            conversation.hasUnreadForCustomer = false
            try await conversation.save(on: req.db)
        }
        return conversation.toDTO(includeMessages: true)
    }

    func customerReply(req: Request) async throws -> ConversationDTO {
        struct ReplyRequest: Content { let message: String }
        let data = try req.content.decode(ReplyRequest.self)
        guard !data.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Message cannot be empty")
        }

        let conversation = try await requireMyConversation(req: req)
        let user = req.auth.get(User.self)

        let message = Message(
            conversationID: try conversation.requireID(),
            senderType: .customer,
            senderName: conversation.customerName,
            senderUserID: user?.id,
            body: data.message
        )
        try await message.save(on: req.db)

        conversation.hasUnreadForAdmin = true
        conversation.lastMessageAt = Date()
        if conversation.status == .closed { conversation.status = .open }  // reopen on new reply
        try await conversation.save(on: req.db)

        try await loadMessagesSorted(conversation, on: req.db)
        return conversation.toDTO(includeMessages: true)
    }

    // MARK: - Admin

    func adminListConversations(req: Request) async throws -> [ConversationDTO] {
        var query = Conversation.query(on: req.db)
        if let status = req.query[String.self, at: "status"],
           let parsed = ConversationStatus(rawValue: status) {
            query = query.filter(\.$status == parsed)
        }
        let conversations = try await query.sort(\.$lastMessageAt, .descending).all()
        return conversations.map { $0.toDTO() }
    }

    func adminGetConversation(req: Request) async throws -> ConversationDTO {
        guard let id = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID")
        }
        guard let conversation = try await Conversation.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Conversation not found")
        }
        try await loadMessagesSorted(conversation, on: req.db)

        if conversation.hasUnreadForAdmin {
            conversation.hasUnreadForAdmin = false
            try await conversation.save(on: req.db)
        }
        return conversation.toDTO(includeMessages: true)
    }

    func adminReply(req: Request) async throws -> ConversationDTO {
        let admin = try req.auth.require(Admin.self)
        struct ReplyRequest: Content { let message: String }
        let data = try req.content.decode(ReplyRequest.self)
        guard !data.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Message cannot be empty")
        }

        guard let id = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID")
        }
        guard let conversation = try await Conversation.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Conversation not found")
        }

        let message = Message(
            conversationID: try conversation.requireID(),
            senderType: .admin,
            senderName: admin.name,
            senderAdminID: admin.id,
            body: data.message
        )
        try await message.save(on: req.db)

        // First responder takes ownership if unassigned.
        if conversation.$assignedAdmin.id == nil {
            conversation.$assignedAdmin.id = admin.id
        }
        conversation.hasUnreadForCustomer = true
        conversation.hasUnreadForAdmin = false
        conversation.lastMessageAt = Date()
        try await conversation.save(on: req.db)

        req.logger.info("Admin \(admin.email) replied to conversation \(id)")

        // Email the reply to the customer from the support mailbox (best-effort —
        // a send failure must not fail the in-app reply). No-op if SMTP isn't configured.
        if let emailConfig = EmailConfiguration.fromEnvironment() {
            let service = EmailService(config: emailConfig, logger: req.logger)
            let customerEmail = conversation.customerEmail
            let customerName = conversation.customerName
            let subject = "Re: \(conversation.subject) — Naturally Yours"
            let body = """
            \(data.message)

            —
            \(admin.name), Naturally Yours Support

            (You can also view and reply to this conversation in the Naturally Yours app.)
            """
            do {
                try await service.send(to: customerEmail, name: customerName, subject: subject, body: body)
                req.logger.info("Support email sent to \(customerEmail) for conversation \(id)")
            } catch {
                req.logger.error("Failed to email support reply to \(customerEmail): \(String(reflecting: error))")
            }
        }

        try await loadMessagesSorted(conversation, on: req.db)
        return conversation.toDTO(includeMessages: true)
    }

    func adminUpdateConversation(req: Request) async throws -> ConversationDTO {
        let admin = try req.auth.require(Admin.self)
        guard let id = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID")
        }
        guard let conversation = try await Conversation.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Conversation not found")
        }

        struct UpdateRequest: Content {
            let status: ConversationStatus?
            let assignToMe: Bool?
        }
        let data = try req.content.decode(UpdateRequest.self)
        if let status = data.status { conversation.status = status }
        if data.assignToMe == true { conversation.$assignedAdmin.id = admin.id }
        try await conversation.save(on: req.db)

        return conversation.toDTO()
    }

    // MARK: - Helpers

    /// Eager-loads a conversation's messages in chronological order.
    private func loadMessagesSorted(_ conversation: Conversation, on db: any Database) async throws {
        let messages = try await conversation.$messages.query(on: db)
            .sort(\.$createdAt, .ascending)
            .all()
        conversation.$messages.value = messages
    }

    private func getOrCreateSessionID(req: Request) -> String {
        if let existing = req.session.data["contact_session_id"] {
            return existing
        }
        let new = UUID().uuidString
        req.session.data["contact_session_id"] = new
        return new
    }

    /// Query for the current customer's conversations (by user or guest session).
    private func myConversationsQuery(req: Request) throws -> QueryBuilder<Conversation> {
        if let user = req.auth.get(User.self), let userID = user.id {
            return Conversation.query(on: req.db).filter(\.$user.$id == userID)
        } else if let sessionID = req.session.data["contact_session_id"] {
            return Conversation.query(on: req.db).filter(\.$sessionID == sessionID)
        } else {
            // No identity → return an empty result set.
            return Conversation.query(on: req.db).filter(\.$id == UUID())
        }
    }

    /// Fetches a conversation and verifies it belongs to the current customer.
    private func requireMyConversation(req: Request) async throws -> Conversation {
        guard let id = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID")
        }
        guard let conversation = try await Conversation.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Conversation not found")
        }
        if let user = req.auth.get(User.self), let userID = user.id {
            guard conversation.$user.id == userID else {
                throw Abort(.forbidden, reason: "This conversation does not belong to you")
            }
        } else {
            let sessionID = req.session.data["contact_session_id"]
            guard let sessionID, conversation.sessionID == sessionID else {
                throw Abort(.forbidden, reason: "This conversation does not belong to you")
            }
        }
        return conversation
    }
}
