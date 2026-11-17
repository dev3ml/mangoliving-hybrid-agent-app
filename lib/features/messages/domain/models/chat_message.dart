import 'chat_thread.dart';

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
    this.senderName = '',
    this.mine,
  });

  final String id;
  final String agentClientId;
  final String text;
  final String senderRole;
  final String createdAt;
  final String? deletedAt;
  final String? readByAgentAt;
  final String? readByBuyerAt;
  final String senderName;
  final bool? mine;

  bool get isMine => mine ?? senderRole == 'agent';
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
      senderName: senderName,
      mine: mine,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final String clientId = (json['agentClientId'] ?? '').toString();
    final String threadId = (json['threadId'] ?? '').toString();
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      agentClientId: clientId.isNotEmpty
          ? clientId
          : (threadId.isEmpty ? '' : ChatThread.inspectionKey(threadId)),
      text: (json['text'] as String?) ?? '',
      senderRole: (json['senderRole'] as String?) ?? 'buyer',
      createdAt: (json['createdAt'] as String?) ?? '',
      deletedAt: json['deletedAt'] as String?,
      readByAgentAt: json['readByAgentAt'] as String?,
      readByBuyerAt: json['readByBuyerAt'] as String?,
      senderName: (json['senderName'] as String?) ?? '',
      mine: json['mine'] is bool ? json['mine'] as bool : null,
    );
  }
}
