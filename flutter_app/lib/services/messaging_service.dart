import '../api_client.dart';
import '../models/conversation.dart';

/// Customer-side messaging (/api/contact, /api/conversations).
class MessagingService {
  Future<List<Conversation>> loadConversations() async {
    final data = await ApiClient.shared.get('/api/conversations');
    final list = (data as List?) ?? const [];
    return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Conversation> start({
    required String subject,
    required String message,
    String? name,
    String? email,
  }) async {
    final data = await ApiClient.shared.post('/api/contact', data: {
      'subject': subject,
      'message': message,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    });
    return Conversation.fromJson(data as Map<String, dynamic>);
  }

  Future<Conversation> conversation(String id) async {
    final data = await ApiClient.shared.get('/api/conversations/$id');
    return Conversation.fromJson(data as Map<String, dynamic>);
  }

  Future<Conversation> reply(String id, String message) async {
    final data = await ApiClient.shared.post(
      '/api/conversations/$id/messages',
      data: {'message': message},
    );
    return Conversation.fromJson(data as Map<String, dynamic>);
  }
}
