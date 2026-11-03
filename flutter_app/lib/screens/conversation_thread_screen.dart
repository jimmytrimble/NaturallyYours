import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../services/messaging_service.dart';
import '../theme.dart';

/// A customer conversation thread with a reply bar and light polling for replies.
class ConversationThreadScreen extends StatefulWidget {
  const ConversationThreadScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  State<ConversationThreadScreen> createState() => _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  final _service = MessagingService();
  final _reply = TextEditingController();
  Conversation? _conversation;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await _service.conversation(widget.conversationId);
      if (mounted) setState(() => _conversation = c);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final c = await _service.reply(widget.conversationId, text);
      if (mounted) {
        setState(() {
          _conversation = c;
          _reply.clear();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation?.messages ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(_conversation?.subject ?? 'Conversation')),
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
          _replyBar(),
        ],
      ),
    );
  }

  Widget _replyBar() {
    return Material(
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
    );
  }
}

/// A chat bubble; customer messages align right (pink), admin left (grey).
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isCustomer;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? NYTheme.pink : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.senderName,
                style: TextStyle(
                    fontSize: 11,
                    color: mine ? Colors.white70 : Colors.grey)),
            const SizedBox(height: 2),
            Text(message.body,
                style: TextStyle(color: mine ? Colors.white : null)),
          ],
        ),
      ),
    );
  }
}
