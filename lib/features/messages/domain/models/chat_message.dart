/// `GET/POST /v1/agent/chat/threads/:id/messages` item.
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.agentClientId,
    required this.text,
    required this.senderRole,
    required this.createdAt,
    this.deletedAt,
    this.readByAgentAt,
    this.readByBuyerAt,
  });

  final String id;
  final String agentClientId;
  final String text;
  final String senderRole;
  final String createdAt;
  final String? deletedAt;
  final String? readByAgentAt;
  final String? readByBuyerAt;

  bool get isMine => senderRole == 'agent';
  bool get isDeleted => deletedAt != null && deletedAt!.isNotEmpty;
  bool get isReadByBuyer => readByBuyerAt != null && readByBuyerAt!.isNotEmpty;

  String get displayText => isDeleted ? 'This message was deleted' : text;

  ChatMessage copyWith({String? readByBuyerAt}) {
    return ChatMessage(
      id: id,
      agentClientId: agentClientId,
      text: text,
      senderRole: senderRole,
      createdAt: createdAt,
      deletedAt: deletedAt,
      readByAgentAt: readByAgentAt,
      readByBuyerAt: readByBuyerAt ?? this.readByBuyerAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      agentClientId: (json['agentClientId'] ?? '').toString(),
      text: (json['text'] as String?) ?? '',
      senderRole: (json['senderRole'] as String?) ?? 'buyer',
      createdAt: (json['createdAt'] as String?) ?? '',
      deletedAt: json['deletedAt'] as String?,
      readByAgentAt: json['readByAgentAt'] as String?,
      readByBuyerAt: json['readByBuyerAt'] as String?,
    );
  }
}
