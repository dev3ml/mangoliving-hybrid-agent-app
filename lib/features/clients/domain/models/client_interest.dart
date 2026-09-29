import 'buyer_fields.dart';

/// `GET /v1/agent/interests` row.
final class ClientInterest {
  const ClientInterest({
    required this.id,
    required this.buyerId,
    required this.name,
    required this.email,
    this.phone = '',
    this.message,
    this.status = 'new',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String buyerId;
  final String name;
  final String email;
  final String phone;
  final String? message;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  factory ClientInterest.fromJson(Map<String, dynamic> json) {
    final BuyerFields buyer = BuyerFields.parse(json['buyer']);
    final String buyerId = buyer.id.isNotEmpty
        ? buyer.id
        : (json['buyerId'] ?? json['_id'] ?? json['id'] ?? '').toString();
    return ClientInterest(
      id: (json['_id'] ?? json['id'] ?? buyerId).toString(),
      buyerId: buyerId,
      name: buyer.name.isNotEmpty
          ? buyer.name
          : (buyer.email.isNotEmpty ? buyer.email : 'Unknown Client'),
      email: buyer.email,
      phone: buyer.phone,
      message: json['message'] as String?,
      status: ((json['status'] as String?) ?? 'new').toLowerCase(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}
