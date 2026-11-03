import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../services/admin_service.dart';
import '../../theme.dart';
import '../conversation_thread_screen.dart'; // MessageBubble

/// Shared admin support inbox.
class AdminInbox extends StatefulWidget {
  const AdminInbox({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminInbox> createState() => _AdminInboxState();
}

class _AdminInboxState extends State<AdminInbox> {
  List<Conversation> _conversations = [];
  bool _loading = true;
  String _filter = 'open'; // open | all | closed

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _conversations = await widget.service.loadConversations(status: _filter == 'all' ? null : _filter);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'open', label: Text('Open')),
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'closed', label: Text('Closed')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) {
              setState(() => _filter = s.first);
              _load();
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
                  ? const Center(child: Text('No conversations', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = _conversations[i];
                          return ListTile(
                            leading: c.hasUnreadForAdmin
                                ? const CircleAvatar(radius: 5, backgroundColor: NYTheme.pink)
                                : const SizedBox(width: 10),
                            title: Text(c.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${c.customerName} · ${c.customerEmail}',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(c.isClosed ? 'Closed' : 'Open',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            onTap: c.id == null
                                ? null
                                : () async {
                                    await Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => _AdminThread(service: widget.service, conversationId: c.id!),
                                    ));
                                    _load();
                                  },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _AdminThread extends StatefulWidget {
  const _AdminThread({required this.service, required this.conversationId});
  final AdminService service;
  final String conversationId;

  @override
  State<_AdminThread> createState() => _AdminThreadState();
}

class _AdminThreadState extends State<_AdminThread> {
  Conversation? _conversation;
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await widget.service.conversation(widget.conversationId);
      if (mounted) setState(() => _conversation = c);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final c = await widget.service.reply(widget.conversationId, text);
      if (mounted) setState(() { _conversation = c; _reply.clear(); });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleClosed() async {
    final closed = _conversation?.isClosed ?? false;
    await widget.service.updateConversation(widget.conversationId, status: closed ? 'open' : 'closed');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation?.messages ?? const [];
    final closed = _conversation?.isClosed ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation?.subject ?? 'Conversation'),
        actions: [
          IconButton(
            tooltip: closed ? 'Reopen' : 'Mark closed',
            icon: Icon(closed ? Icons.mark_email_unread_outlined : Icons.check_circle_outline),
            onPressed: _toggleClosed,
          ),
          IconButton(
            tooltip: 'Assign to me',
            icon: const Icon(Icons.person_add_alt),
            onPressed: () async {
              await widget.service.updateConversation(widget.conversationId, assignToMe: true);
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversation == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => MessageBubble(message: messages[i]),
                  ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reply,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Reply…',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _sending
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: NYTheme.pink),
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
