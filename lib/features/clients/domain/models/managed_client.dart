import 'buyer_fields.dart';

/// `GET /v1/agent/clients` row used by Overview and Clients.
final class ManagedClient {
  const ManagedClient({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.phone = '',
    this.buyerId,
    this.invitationSent = false,
    this.invitedAt,
    this.inviteDeclinedAt,
    this.revokedAt,
    this.notes,
    this.shareSearchInsights,
    this.canViewSearchInsights,
    this.privacyMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final String phone;
  final String? buyerId;
  final bool invitationSent;
  final String? invitedAt;
  final String? inviteDeclinedAt;
  final String? revokedAt;
  final String? notes;
  final bool? shareSearchInsights;
  final bool? canViewSearchInsights;
  final String? privacyMessage;
  final String? createdAt;
  final String? updatedAt;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'New client';
  }

  factory ManagedClient.fromJson(Map<String, dynamic> json) {
    final BuyerFields buyer = BuyerFields.parse(json['buyerId']);
    String email = (json['email'] as String?) ?? '';
    String name = (json['name'] as String?) ?? '';
    String phone = (json['phone'] as String?) ?? '';
    if (email.isEmpty) email = buyer.email;
    if (name.isEmpty) name = buyer.name;
    if (phone.isEmpty) phone = buyer.phone;
    return ManagedClient(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: name,
      email: email,
      phone: phone,
      status: (json['status'] as String?) ?? '',
      buyerId: buyer.id.isEmpty ? null : buyer.id,
      invitationSent: json['invitationSent'] == true,
      invitedAt: json['invitedAt'] as String?,
      inviteDeclinedAt: json['inviteDeclinedAt'] as String?,
      revokedAt: json['revokedAt'] as String?,
      notes: json['notes'] as String?,
      shareSearchInsights: json['shareSearchInsights'] as bool?,
      canViewSearchInsights: json['canViewSearchInsights'] as bool?,
      privacyMessage: json['privacyMessage'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}
