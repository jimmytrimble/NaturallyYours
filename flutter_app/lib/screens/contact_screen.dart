import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../models/conversation.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../theme.dart';
import 'conversation_thread_screen.dart';

/// Customer contact center: list conversations + start a new one.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _service = MessagingService();
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _conversations = await _service.loadConversations();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _compose() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ComposeSheet(),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: NYTheme.pink,
        onPressed: _compose,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('New Message', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = _conversations[i];
                      return ListTile(
                        title: Text(c.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(c.customerEmail),
                        trailing: c.hasUnreadForCustomer
                            ? const CircleAvatar(radius: 5, backgroundColor: NYTheme.pink)
                            : Text(c.isClosed ? 'Closed' : 'Open',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        onTap: c.id == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ConversationThreadScreen(conversationId: c.id!),
                                )),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: NYTheme.pink.withOpacity(0.12),
                child: const Icon(Icons.forum, color: NYTheme.pink, size: 34),
              ),
              const SizedBox(height: 12),
              const Text('How Can We Help?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Questions about products, orders, or anything else? Our team is here.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}

/// Inquiry topics mirroring the website contact form.
const _topics = [
  'Product & Brand Inquiry',
  'Order Inquiry',
  'Job Inquiry',
  'Vending Machine Support',
  'General Question / Other',
];

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _service = MessagingService();
  String _topic = _topics.first;
  final _message = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send(bool isGuest) async {
    if (_message.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a message.');
      return;
    }
    if (isGuest && (_name.text.trim().isEmpty || !_email.text.contains('@'))) {
      setState(() => _error = 'Name and a valid email are required.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _service.start(
        subject: _topic,
        message: _message.text.trim(),
        name: isGuest ? _name.text.trim() : null,
        email: isGuest ? _email.text.trim() : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Could not send.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !context.read<AuthService>().isAuthenticated;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (isGuest) ...[
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 10),
          ],
          DropdownButtonFormField<String>(
            value: _topic,
            decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
            items: [for (final t in _topics) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _topic = v ?? _topic),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NYTheme.pink, minimumSize: const Size.fromHeight(48)),
            onPressed: _sending ? null : () => _send(isGuest),
            child: _sending
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send'),
          ),
        ],
      ),
    );
  }
}
