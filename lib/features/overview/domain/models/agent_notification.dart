/// `GET /v1/agent/notifications` item.
final class AgentNotification {
  const AgentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.message,
    this.link,
    this.clientId,
  });

  final String id;
  final String type;
  final String title;
  final String createdAt;
  final String? message;
  final String? link;
  final String? clientId;

  DateTime? get createdAtDate => DateTime.tryParse(createdAt);

  bool isUnread(DateTime? lastReadAt) {
    if (lastReadAt == null) return true;
    final DateTime? created = createdAtDate;
    if (created == null) return true;
    return created.isAfter(lastReadAt);
  }

  factory AgentNotification.fromJson(Map<String, dynamic> json) {
    return AgentNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      message: json['message'] as String?,
      createdAt: (json['createdAt'] as String?) ?? '',
      link: json['link'] as String?,
      clientId: json['clientId']?.toString(),
    );
  }
}
