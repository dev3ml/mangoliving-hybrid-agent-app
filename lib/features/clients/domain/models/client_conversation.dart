import 'buyer_fields.dart';

final class ConversationMessage {
  const ConversationMessage({
    required this.text,
    required this.isUser,
    this.createdAt,
  });

  final String text;
  final bool isUser;
  final String? createdAt;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      text: (json['text'] as String?) ?? '',
      isUser: json['isUser'] == true,
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// `GET /v1/agent/conversations` summary or detail.
final class ClientConversation {
  const ClientConversation({
    required this.id,
    required this.buyerId,
    required this.name,
    this.email = '',
    this.phone = '',
    this.lastMessageAt,
    this.updatedAt,
    this.criteria,
    this.messages = const <ConversationMessage>[],
  });

  final String id;
  final String buyerId;
  final String name;
  final String email;
  final String phone;
  final String? lastMessageAt;
  final String? updatedAt;
  final Map<String, dynamic>? criteria;
  final List<ConversationMessage> messages;

  factory ClientConversation.fromJson(Map<String, dynamic> json) {
    final BuyerFields buyer = BuyerFields.parse(json['buyer'] ?? json['userId']);
    String buyerId = buyer.id;
    if (buyerId.isEmpty) {
      final dynamic userId = json['userId'];
      if (userId is String) buyerId = userId;
    }
    final List<ConversationMessage> messages = <ConversationMessage>[];
    final dynamic raw = json['messages'];
    if (raw is List) {
      for (final dynamic item in raw) {
        if (item is Map<String, dynamic>) {
          messages.add(ConversationMessage.fromJson(item));
        }
      }
    }
    final Map<String, dynamic>? criteria =
        json['criteria'] is Map<String, dynamic>
            ? json['criteria'] as Map<String, dynamic>
            : null;
    return ClientConversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      buyerId: buyerId,
      name: buyer.name.isNotEmpty
          ? buyer.name
          : (buyer.email.isNotEmpty ? buyer.email : 'Unknown Client'),
      email: buyer.email,
      phone: buyer.phone,
      lastMessageAt: json['lastMessageAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      criteria: criteria,
      messages: messages,
    );
  }
}
