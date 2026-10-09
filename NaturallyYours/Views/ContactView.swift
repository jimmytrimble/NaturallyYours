import SwiftUI

/// Customer contact center: start a new conversation and view existing threads.
struct ContactView: View {
    @Environment(MessagingService.self) private var messaging
    @EnvironmentObject private var authService: AuthService

    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if messaging.isLoading && messaging.conversations.isEmpty {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if messaging.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .background(Color.nyWhite)
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.nyPink)
                    }
                }
            }
            .navigationDestination(for: ConversationDTO.self) { conversation in
                ConversationThreadView(conversationID: conversation.id)
            }
            .task { await messaging.loadConversations() }
            .refreshable { await messaging.loadConversations() }
            .sheet(isPresented: $showCompose) {
                ComposeMessageView()
                    .environment(messaging)
                    .environmentObject(authService)
            }
        }
    }

    private var conversationList: some View {
        List {
            ForEach(messaging.conversations) { conversation in
                NavigationLink(value: conversation) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(conversation.subject)
                                .font(.nyBody(15))
                                .fontWeight(.semibold)
                                .foregroundStyle(.nyBlack)
                            if conversation.hasUnreadForCustomer {
                                Circle().fill(Color.nyPink).frame(width: 8, height: 8)
                            }
                            Spacer()
                            Text(conversation.status == .closed ? "Closed" : "Open")
                                .font(.nyCaption(11))
                                .foregroundStyle(.nyGray)
                        }
                        Text(conversation.customerEmail)
                            .font(.nyCaption(12))
                            .foregroundStyle(.nyGray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Messages Yet", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Have a question? Start a conversation with our team.")
        } actions: {
            Button("New Message") { showCompose = true }
                .buttonStyle(.borderedProminent)
                .tint(.nyPink)
        }
    }
}

// MARK: - Compose

/// Inquiry topics, mirroring the categories on the Naturally Yours website contact form.
enum InquiryTopic: String, CaseIterable, Identifiable {
    case productBrand = "Product & Brand Inquiry"
    case order = "Order Inquiry"
    case job = "Job Inquiry"
    case vending = "Vending Machine Support"
    case general = "General Question / Other"

    var id: String { rawValue }
}

struct ComposeMessageView: View {
    @Environment(MessagingService.self) private var messaging
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var topic: InquiryTopic = .productBrand
    @State private var messageBody = ""
    @State private var guestName = ""
    @State private var guestEmail = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var isGuest: Bool { !authService.isAuthenticated }

    private var isValid: Bool {
        !messageBody.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!isGuest || (!guestName.trimmingCharacters(in: .whitespaces).isEmpty && guestEmail.contains("@")))
    }

    var body: some View {
        NavigationStack {
            Form {
                if isGuest {
                    Section("Your Details") {
                        TextField("Name", text: $guestName)
                            .textContentType(.name)
                        TextField("Email", text: $guestEmail)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                }
                Section("Topic") {
                    Picker("What's this about?", selection: $topic) {
                        ForEach(InquiryTopic.allCases) { topic in
                            Text(topic.rawValue).tag(topic)
                        }
                    }
                }
                Section("Message") {
                    TextField("Type your message…", text: $messageBody, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { send() }
                        .disabled(!isValid || isSending)
                }
            }
            .alert("Couldn't Send", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private func send() {
        isSending = true
        Task {
            do {
                _ = try await messaging.startConversation(
                    subject: topic.rawValue,
                    message: messageBody,
                    name: isGuest ? guestName : nil,
                    email: isGuest ? guestEmail : nil
                )
                await messaging.loadConversations()
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isSending = false
        }
    }
}

// MARK: - Thread

struct ConversationThreadView: View {
    let conversationID: UUID?

    @Environment(MessagingService.self) private var messaging

    @State private var conversation: ConversationDTO?
    @State private var replyText = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation?.messages ?? []) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: conversation?.messages.count ?? 0) { _, _ in
                    if let last = conversation?.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            replyBar
        }
        .background(Color.nyWhite)
        .navigationTitle(conversation?.subject ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
            await pollForReplies()
        }
    }

    private var replyBar: some View {
        HStack(spacing: 10) {
            TextField("Reply…", text: $replyText, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color.nyLightGray)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                sendReply()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? .nyPink : .nyGray)
            }
            .disabled(!canSend || isSending)
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !replyText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func load() async {
        guard let conversationID else { return }
        conversation = try? await messaging.conversation(id: conversationID)
    }

    /// Lightweight polling so admin replies appear while the thread is open.
    private func pollForReplies() async {
        guard let conversationID else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled { break }
            if let updated = try? await messaging.conversation(id: conversationID) {
                conversation = updated
            }
        }
    }

    private func sendReply() {
        guard let conversationID, canSend else { return }
        let text = replyText
        isSending = true
        Task {
            if let updated = try? await messaging.reply(conversationID: conversationID, message: text) {
                conversation = updated
                replyText = ""
            }
            isSending = false
        }
    }
}

struct MessageBubble: View {
    let message: MessageDTO

    private var isCustomer: Bool { message.senderType == .customer }

    var body: some View {
        HStack {
            if isCustomer { Spacer(minLength: 40) }

            VStack(alignment: isCustomer ? .trailing : .leading, spacing: 3) {
                Text(message.senderName)
                    .font(.nyCaption(11))
                    .foregroundStyle(.nyGray)
                Text(message.body)
                    .font(.nyBody(15))
                    .foregroundStyle(isCustomer ? .white : .nyBlack)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCustomer ? Color.nyPink : Color.nyLightGray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !isCustomer { Spacer(minLength: 40) }
        }
    }
}

extension ConversationDTO: Hashable {
    static func == (lhs: ConversationDTO, rhs: ConversationDTO) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
