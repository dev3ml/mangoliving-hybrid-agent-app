import 'property_search_logic.dart';

/// One row from the agent favorites or hidden-listings endpoints.
final class SavedListing {
  const SavedListing({
    required this.id,
    required this.address,
    required this.priceLabel,
    this.locality = '',
    this.imageUrl,
    this.beds,
    this.baths,
    this.status,
    this.matchPercent,
    this.url,
  });

  final String id;
  final String address;
  final String priceLabel;
  final String locality;
  final String? imageUrl;
  final String? beds;
  final String? baths;
  final String? status;
  final int? matchPercent;
  final String? url;

  factory SavedListing.fromJson(
    Map<String, dynamic> json, {
    required String buyerAppUrl,
  }) {
    final String street = _string(json['streetAddress']) ?? _string(json['address']) ?? '';
    final String city = _string(json['city']) ?? '';
    final String province = _string(json['province']) ?? '';
    final String locality = <String>[city, province].where((String p) => p.isNotEmpty).join(', ');
    final String address = street.isNotEmpty
        ? street
        : (locality.isNotEmpty ? locality : 'Property');
    final Object? price = json['price'];
    final Object? priceValue = price is Map ? price['value'] : price;
    final String base = buyerAppUrl.replaceAll(RegExp(r'/+$'), '');
    final String? path = _string(json['propertyPath']);
    String? url;
    if (path != null && base.isNotEmpty) {
      url = path.startsWith('/') ? '$base$path' : '$base/$path';
    }
    final Object? match = json['Percentage'];
    return SavedListing(
      id: (json['propertyid'] ?? json['id'] ?? address).toString(),
      address: address,
      locality: street.isNotEmpty ? locality : '',
      priceLabel: formatListingPrice(priceValue),
      imageUrl: _image(json),
      beds: _metric(json['bedrooms']),
      baths: _metric(json['bathrooms']),
      status: _string(json['mostRecentStatus']),
      matchPercent: match is num ? match.round() : null,
      url: url,
    );
  }
}

String? _image(Map<String, dynamic> json) {
  final String? first = _string(json['firstImageURL']);
  if (first != null) return first;
  final Object? image = json['Image'];
  if (image is Map) return _string(image['value']);
  return null;
}

String? _metric(Object? raw) {
  final Object? value = raw is Map ? raw['value'] : raw;
  if (value == null) return null;
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _string(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
