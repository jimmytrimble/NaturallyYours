import SwiftUI

/// Shared admin support inbox: browse conversations and reply.
struct AdminInboxView: View {
    @Environment(AdminService.self) private var adminService

    enum Filter: String, CaseIterable {
        case open = "Open"
        case all = "All"
        case closed = "Closed"

        var status: ConversationStatus? {
            switch self {
            case .open: return .open
            case .closed: return .closed
            case .all: return nil
            }
        }
    }

    @State private var filter: Filter = .open
    @State private var conversations: [ConversationDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: filter) { _, _ in Task { await load() } }

            List {
                ForEach(conversations) { conversation in
                    NavigationLink {
                        AdminConversationThreadView(conversationID: conversation.id)
                    } label: {
                        HStack(spacing: 10) {
                            if conversation.hasUnreadForAdmin {
                                Circle().fill(Color.nyPink).frame(width: 8, height: 8)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(conversation.subject)
                                    .font(.nyBody(15)).fontWeight(.semibold)
                                    .foregroundStyle(.nyBlack)
                                Text("\(conversation.customerName) · \(conversation.customerEmail)")
                                    .font(.nyCaption(12)).foregroundStyle(.nyGray)
                            }
                            Spacer()
                            Text(conversation.status == .closed ? "Closed" : "Open")
                                .font(.nyCaption(11)).foregroundStyle(.nyGray)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if isLoading && conversations.isEmpty { ProgressView() }
                else if !isLoading && conversations.isEmpty {
                    ContentUnavailableView("No Conversations", systemImage: "tray")
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .adminToolbar()
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            conversations = try await adminService.loadConversations(status: filter.status)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - Admin thread

struct AdminConversationThreadView: View {
    let conversationID: UUID?

    @Environment(AdminService.self) private var adminService

    @State private var conversation: ConversationDTO?
    @State private var replyText = ""
    @State private var isSending = false

    private var isClosed: Bool { conversation?.status == .closed }

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        setStatus(isClosed ? .open : .closed)
                    } label: {
                        Label(isClosed ? "Reopen" : "Mark Closed",
                              systemImage: isClosed ? "envelope.open" : "checkmark.circle")
                    }
                    Button {
                        assignToMe()
                    } label: {
                        Label("Assign to Me", systemImage: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(.nyPink)
                }
            }
        }
        .task { await load() }
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
        conversation = try? await adminService.conversation(id: conversationID)
    }

    private func sendReply() {
        guard let conversationID, canSend else { return }
        let text = replyText
        isSending = true
        Task {
            if let updated = try? await adminService.reply(conversationID: conversationID, message: text) {
                conversation = updated
                replyText = ""
            }
            isSending = false
        }
    }

    private func setStatus(_ status: ConversationStatus) {
        guard let conversationID else { return }
        Task {
            // The update endpoint returns a DTO without messages, so reload the full
            // thread rather than replacing `conversation` with a message-less copy.
            _ = try? await adminService.updateConversation(id: conversationID, status: status)
            await load()
        }
    }

    private func assignToMe() {
        guard let conversationID else { return }
        Task {
            _ = try? await adminService.updateConversation(id: conversationID, assignToMe: true)
            await load()
        }
    }
}
