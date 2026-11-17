/// `GET /v1/agent/chat/threads` row, or an inspection group room.
final class ChatThread {
  static const String inspectionPrefix = 'inspection:';

  static String inspectionKey(String threadId) => '$inspectionPrefix$threadId';

  const ChatThread({
    required this.agentClientId,
    required this.buyerName,
    required this.unreadCount,
    required this.updatedAt,
    this.buyerId,
    this.buyerEmail = '',
    this.avatarUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastSenderRole,
  });

  final String agentClientId;
  final String buyerName;
  final String? buyerId;
  final String buyerEmail;
  final String? avatarUrl;
  final String? lastMessageText;
  final String? lastMessageAt;
  final String? lastSenderRole;
  final int unreadCount;
  final String updatedAt;

  bool get isInspection => agentClientId.startsWith(inspectionPrefix);

  String get bareId =>
      isInspection ? agentClientId.substring(inspectionPrefix.length) : agentClientId;

  bool get hasLastMessage =>
      lastMessageText != null || lastMessageAt != null || lastSenderRole != null;

  String get preview {
    final String text = (lastMessageText ?? '').trim();
    if (text.isEmpty) return 'No messages yet';
    if (isInspection) {
      final String who = switch (lastSenderRole) {
        'agent' => 'Agent',
        'buyer' => 'Buyer',
        'inspector' => 'Inspector',
        _ => '',
      };
      return who.isEmpty ? text : '$who: $text';
    }
    final String prefix = lastSenderRole == 'agent' ? 'You: ' : '';
    return '$prefix$text';
  }

  String get sortAt => lastMessageAt ?? updatedAt;

  String get initials {
    final List<String> parts = buyerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    if (buyerEmail.isNotEmpty) return buyerEmail[0].toUpperCase();
    return 'C';
  }

  ChatThread copyWith({
    int? unreadCount,
    String? lastMessageText,
    String? lastMessageAt,
    String? lastSenderRole,
    String? updatedAt,
  }) {
    return ChatThread(
      agentClientId: agentClientId,
      buyerName: buyerName,
      buyerId: buyerId,
      buyerEmail: buyerEmail,
      avatarUrl: avatarUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderRole: lastSenderRole ?? this.lastSenderRole,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final dynamic buyer = json['buyer'];
    String name = 'Client';
    String email = '';
    String? avatar;
    String? buyerId;
    if (buyer is Map<String, dynamic>) {
      final String combined =
          '${buyer['firstName'] ?? ''} ${buyer['lastName'] ?? ''}'.trim();
      email = (buyer['email'] as String?) ?? '';
      name = combined.isNotEmpty ? combined : (email.isNotEmpty ? email : 'Client');
      avatar = buyer['avatarUrl'] as String?;
      buyerId = (buyer['id'] ?? buyer['_id'])?.toString();
    }
    final dynamic last = json['lastMessage'];
    String? text;
    String? createdAt;
    String? role;
    if (last is Map<String, dynamic>) {
      text = last['text'] as String?;
      createdAt = last['createdAt'] as String?;
      role = last['senderRole'] as String?;
    }
    return ChatThread(
      agentClientId: (json['agentClientId'] ?? '').toString(),
      buyerName: name,
      buyerId: buyerId,
      buyerEmail: email,
      avatarUrl: avatar,
      lastMessageText: text,
      lastMessageAt: createdAt,
      lastSenderRole: role,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as String?) ?? '',
    );
  }

  /// `GET /v1/inspection-chat/threads` row.
  factory ChatThread.inspectionFromJson(Map<String, dynamic> json) {
    final dynamic last = json['lastMessage'];
    String? text;
    String? createdAt;
    String? role;
    if (last is Map<String, dynamic>) {
      text = last['text'] as String?;
      createdAt = last['createdAt'] as String?;
      role = last['senderRole'] as String?;
    }
    final String title = (json['title'] as String?)?.trim() ?? '';
    return ChatThread(
      agentClientId: inspectionKey((json['id'] ?? '').toString()),
      buyerName: title.isEmpty ? 'Inspection' : title,
      buyerEmail: 'Inspection',
      lastMessageText: text,
      lastMessageAt: createdAt,
      lastSenderRole: role,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as String?) ?? createdAt ?? '',
    );
  }
}
