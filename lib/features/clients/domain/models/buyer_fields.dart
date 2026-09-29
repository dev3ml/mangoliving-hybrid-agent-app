/// Shared parser for populated `buyer` / `buyerId` / `userId` objects.
final class BuyerFields {
  const BuyerFields({
    this.id = '',
    this.name = '',
    this.email = '',
    this.phone = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  static BuyerFields parse(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return BuyerFields(id: raw.trim());
    }
    if (raw is Map) {
      final Map<String, dynamic> map = raw.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>('$key', value),
      );
      final String id = (map['_id'] ?? map['id'] ?? '').toString();
      final String name =
          '${map['firstName'] ?? ''} ${map['lastName'] ?? ''}'.trim();
      return BuyerFields(
        id: id,
        name: name,
        email: (map['email'] as String?) ?? '',
        phone: (map['mobileNumber'] as String?) ??
            (map['phone'] as String?) ??
            '',
      );
    }
    return const BuyerFields();
  }
}
