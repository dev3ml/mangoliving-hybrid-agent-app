import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/constants/env_config.dart';
import 'package:mangoliving_agent/features/clients/domain/models/criteria_history.dart';
import 'package:mangoliving_agent/features/clients/domain/models/managed_client.dart';
import 'package:mangoliving_agent/features/property_search/domain/property_search_links.dart';
import 'package:mangoliving_agent/features/property_search/domain/property_search_logic.dart';
import 'package:mangoliving_agent/features/property_search/domain/saved_listing.dart';

void main() {
  test('property search opens the site, the app, or the store', () {
    expect(
      PropertySearchLinks.web('https://mangoliving.ai/').toString(),
      'https://mangoliving.ai/search',
    );
    expect(PropertySearchLinks.app.toString(), 'mangoliving://search');
    expect(
      PropertySearchLinks.storeFor(android: false).toString(),
      'https://apps.apple.com/us/app/mangoliving/id6799199646',
    );
    expect(
      PropertySearchLinks.storeFor(android: true).toString(),
      'https://play.google.com/store/apps/details?id=com.mangoliving.mangoliving',
    );
  });

  test('keeps linked active, invited, and passive clients', () {
    expect(isPropertySearchClient(_client(status: 'active', buyerId: 'b1')), isTrue);
    expect(isPropertySearchClient(_client(status: 'invited', buyerId: 'b1')), isTrue);
    expect(isPropertySearchClient(_client(status: 'passive', buyerId: 'b1')), isTrue);
    expect(isPropertySearchClient(_client(status: 'declined', buyerId: 'b1')), isFalse);
    expect(isPropertySearchClient(_client(status: 'active')), isFalse);
  });

  test('sharing is off for a passive link or an explicit opt-out', () {
    expect(isSearchSharingDisabled(_client(status: 'passive', buyerId: 'b1')), isTrue);
    expect(
      isSearchSharingDisabled(
        _client(status: 'active', buyerId: 'b1', shareSearchInsights: false),
      ),
      isTrue,
    );
    expect(isSearchSharingDisabled(_client(status: 'active', buyerId: 'b1')), isFalse);
  });

  test('uses the newest criteria row and its city', () {
    final Map<String, dynamic>? criteria = latestCriteria(<CriteriaHistoryEntry>[
      const CriteriaHistoryEntry(id: 'new', criteria: <String, dynamic>{}),
      const CriteriaHistoryEntry(
        id: 'older',
        criteria: <String, dynamic>{
          'city': <String, dynamic>{'value': 'Austin'},
        },
      ),
    ]);
    expect(cityFromCriteria(criteria), 'Austin');
    expect(
      cityFromCriteria(<String, dynamic>{'city': 'Dallas'}),
      'Dallas',
    );
  });

  test('builds the same recommendation text the web host sends', () {
    final String text = buildPropertyRecommendation(
      buyerAppUrl: 'https://app.mangoliving.ai/',
      properties: const <OutboundProperty>[
        OutboundProperty(
          address: '3505 Sky Ridge Lane',
          city: 'Austin',
          province: 'TX',
          price: '450000',
          path: '/tx/austin/home/1',
        ),
      ],
    );
    expect(text, contains("Here's a property I'd recommend for you:"));
    expect(text, contains(r'$450,000 — 3505 Sky Ridge Lane, Austin, TX'));
    expect(text, contains('https://app.mangoliving.ai/tx/austin/home/1'));
  });

  test('counts favorites and hidden homes from the overview payload', () {
    const Map<String, dynamic> data = <String, dynamic>{
      'stats': <String, dynamic>{
        'favorites': <String, dynamic>{'value': 3},
      },
      'hiddenVsFavorited': <Map<String, dynamic>>[
        <String, dynamic>{'hidden': 2},
        <String, dynamic>{'hidden': 1},
      ],
    };
    expect(favoritesCountFromOverview(data), 3);
    expect(hiddenCountFromOverview(data), 3);
  });

  test('chat socket address drops the api path and port 0', () {
    final String socket = EnvConfig.socketBaseUrl;
    expect(socket.contains(':0'), isFalse);
    expect(socket.endsWith('/api'), isFalse);
    expect(socket, startsWith('https://mangoliving.ai'));
  });

  test('rewrites the missing app host to the live buyer site', () {
    expect(
      normalizeBuyerAppUrl('https://app.mangoliving.ai'),
      'https://mangoliving.ai',
    );
    expect(
      normalizeBuyerAppUrl('https://mangoliving.ai/'),
      'https://mangoliving.ai/',
    );
  });

  test('saved listing opens on the buyer app', () {
    final SavedListing listing = SavedListing.fromJson(
      <String, dynamic>{
        'propertyid': '99',
        'streetAddress': '1 Main',
        'city': 'Austin',
        'province': 'TX',
        'price': <String, dynamic>{'value': 10},
        'propertyPath': '/tx/austin/home/99',
        'bedrooms': <String, dynamic>{'value': '3'},
      },
      buyerAppUrl: 'https://app.mangoliving.ai',
    );
    expect(listing.priceLabel, r'$10');
    expect(listing.url, 'https://app.mangoliving.ai/tx/austin/home/99');
    expect(listing.beds, '3');
  });
}

ManagedClient _client({
  required String status,
  String? buyerId,
  bool? shareSearchInsights,
}) {
  return ManagedClient(
    id: 'c1',
    name: 'Ada',
    email: 'ada@example.com',
    status: status,
    buyerId: buyerId,
    shareSearchInsights: shareSearchInsights,
  );
}
