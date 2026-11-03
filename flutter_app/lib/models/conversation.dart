/// Mirrors the server messaging DTOs.
class Message {
  Message({required this.senderType, required this.senderName, required this.body});
  final String senderType; // "customer" | "admin"
  final String senderName;
  final String body;

  bool get isCustomer => senderType == 'customer';

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        senderType: (j['senderType'] ?? 'customer') as String,
        senderName: (j['senderName'] ?? '') as String,
        body: (j['body'] ?? '') as String,
      );
}

class Conversation {
  Conversation({
    required this.id,
    required this.subject,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.hasUnreadForCustomer,
    required this.hasUnreadForAdmin,
    required this.messages,
  });

  final String? id;
  final String subject;
  final String customerName;
  final String customerEmail;
  final String status; // "open" | "closed"
  final bool hasUnreadForCustomer;
  final bool hasUnreadForAdmin;
  final List<Message> messages;

  bool get isClosed => status == 'closed';

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String?,
        subject: (j['subject'] ?? '') as String,
        customerName: (j['customerName'] ?? '') as String,
        customerEmail: (j['customerEmail'] ?? '') as String,
        status: (j['status'] ?? 'open') as String,
        hasUnreadForCustomer: (j['hasUnreadForCustomer'] ?? false) as bool,
        hasUnreadForAdmin: (j['hasUnreadForAdmin'] ?? false) as bool,
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
