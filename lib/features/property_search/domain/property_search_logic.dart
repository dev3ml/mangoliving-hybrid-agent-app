import 'package:intl/intl.dart';

import '../../clients/domain/models/criteria_history.dart';
import '../../clients/domain/models/managed_client.dart';

const Set<String> propertySearchClientStatuses = <String>{
  'active',
  'invited',
  'passive',
};

const String sharingDisabledFallback =
    "This client has turned off sharing of their search insights. You can search on their behalf, but their saved criteria, favorites, and hidden listings won't be visible.";

/// Clients the web property-search picker shows: linked buyer, still on the roster.
bool isPropertySearchClient(ManagedClient client) {
  final String? buyerId = client.buyerId;
  if (buyerId == null || buyerId.isEmpty) return false;
  final String status = client.status.trim().toLowerCase();
  return status.isEmpty || propertySearchClientStatuses.contains(status);
}

bool isSearchSharingDisabled(ManagedClient client) {
  if (client.shareSearchInsights == false) return true;
  return client.status.trim().toLowerCase() == 'passive';
}

String sharingMessageFor(ManagedClient client) {
  final String custom = (client.privacyMessage ?? '').trim();
  if (custom.isNotEmpty) return custom;
  return sharingDisabledFallback;
}

/// Newest history row that actually stored criteria. The API is newest-first.
Map<String, dynamic>? latestCriteria(List<CriteriaHistoryEntry> history) {
  for (final CriteriaHistoryEntry entry in history) {
    final Map<String, dynamic>? criteria = entry.criteria;
    if (criteria != null && criteria.isNotEmpty) return criteria;
  }
  return null;
}

/// City string the web host copies into the location chips after a criteria load.
String? cityFromCriteria(Map<String, dynamic>? criteria) {
  if (criteria == null) return null;
  final Object? city = criteria['city'];
  if (city is String && city.trim().isNotEmpty) return city.trim();
  if (city is Map) {
    final Object? value = city['value'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

int hiddenCountFromOverview(Map<String, dynamic>? data) {
  final Object? raw = data?['hiddenVsFavorited'];
  if (raw is! List) return 0;
  var sum = 0;
  for (final Object? point in raw) {
    if (point is! Map) continue;
    final Object? hidden = point['hidden'];
    if (hidden is num) sum += hidden.toInt();
  }
  return sum;
}

int favoritesCountFromOverview(Map<String, dynamic>? data) {
  final Object? stats = data?['stats'];
  if (stats is! Map) return 0;
  final Object? favorites = stats['favorites'];
  if (favorites is! Map) return 0;
  final Object? value = favorites['value'];
  if (value is num) return value.toInt();
  return 0;
}

/// A home the embedded buyer search asked us to send.
final class OutboundProperty {
  const OutboundProperty({
    this.propertyId,
    this.address,
    this.city,
    this.province,
    this.price,
    this.path,
  });

  final String? propertyId;
  final String? address;
  final String? city;
  final String? province;
  final String? price;
  final String? path;

  factory OutboundProperty.fromJson(Map<dynamic, dynamic> json) {
    return OutboundProperty(
      propertyId: _text(json['propertyId']),
      address: _text(json['address']),
      city: _text(json['city']),
      province: _text(json['province']),
      price: _text(json['price']),
      path: _text(json['path']),
    );
  }
}

String formatListingPrice(Object? raw) {
  final num? value = switch (raw) {
    final num n => n,
    final String s => num.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')),
    _ => null,
  };
  if (value == null || value == 0 || value.isNaN) return '—';
  return NumberFormat.currency(
    locale: 'en_CA',
    name: 'CAD',
    symbol: r'$',
    decimalDigits: 0,
  ).format(value);
}

String buildPropertyRecommendation({
  required List<OutboundProperty> properties,
  required String buyerAppUrl,
}) {
  final String base = buyerAppUrl.replaceAll(RegExp(r'/+$'), '');
  final String lines = properties
      .asMap()
      .entries
      .map((MapEntry<int, OutboundProperty> entry) {
        final OutboundProperty property = entry.value;
        final String locality = <String?>[
          property.address,
          property.city,
          property.province,
        ].whereType<String>().where((String part) => part.isNotEmpty).join(', ');
        final String priceLabel = formatListingPrice(property.price);
        final String head =
            '${entry.key + 1}. $priceLabel${locality.isEmpty ? '' : ' — $locality'}';
        final String? path = property.path;
        if (path == null || path.isEmpty || base.isEmpty) return head;
        final String link = path.startsWith('/') ? '$base$path' : '$base/$path';
        return '$head\n$link';
      })
      .join('\n\n');
  final String intro = properties.length == 1
      ? "Here's a property I'd recommend for you:"
      : "Here are ${properties.length} properties I'd recommend for you:";
  return '$intro\n\n$lines';
}

String? _text(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
