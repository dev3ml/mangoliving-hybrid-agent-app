import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/clients/domain/models/client_conversation.dart';
import 'package:mangoliving_agent/features/clients/domain/models/client_interest.dart';
import 'package:mangoliving_agent/features/clients/domain/models/criteria_history.dart';
import 'package:mangoliving_agent/features/clients/domain/models/managed_client.dart';
import 'package:mangoliving_agent/features/clients/domain/models/roster_client.dart';
import 'package:mangoliving_agent/features/clients/domain/roster_merge.dart';
import 'package:mangoliving_agent/features/showings/domain/models/showing_request.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 20, 12);

  test('pending managed clients stay in the banner, not the list', () {
    final ClientRoster roster = ClientRosterMerger.merge(
      interests: const <ClientInterest>[],
      conversations: const <ClientConversation>[],
      managed: const <ManagedClient>[
        ManagedClient(
          id: 'p1',
          name: 'Maya',
          email: 'maya@x.com',
          status: 'pending',
        ),
        ManagedClient(
          id: 'a1',
          name: 'Alex',
          email: 'alex@x.com',
          status: 'active',
        ),
      ],
      showings: const <ShowingRequest>[],
      now: now,
    );

    expect(roster.pendingRequests, hasLength(1));
    expect(roster.pendingRequests.single.displayName, 'Maya');
    expect(roster.clients.map((RosterClient c) => c.name), <String>['Alex']);
  });

  test('overlays managed privacy and attaches showing actions', () {
    final ClientRoster roster = ClientRosterMerger.merge(
      interests: const <ClientInterest>[
        ClientInterest(
          id: 'i1',
          buyerId: 'b1',
          name: 'Jordan',
          email: 'jordan@x.com',
          message: 'Looking in Frisco',
        ),
      ],
      conversations: const <ClientConversation>[],
      managed: const <ManagedClient>[
        ManagedClient(
          id: 'm1',
          name: 'Jordan Lee',
          email: 'jordan@x.com',
          status: 'active',
          buyerId: 'b1',
          shareSearchInsights: false,
          privacyMessage: 'Buyer turned off sharing.',
        ),
      ],
      showings: const <ShowingRequest>[
        ShowingRequest(
          id: 's1',
          buyerName: 'Jordan',
          status: 'pending',
          buyerId: 'b1',
          propertyAddress: '120 Oak St',
        ),
      ],
      now: now,
    );

    final RosterClient jordan = roster.clients.single;
    expect(jordan.managedClientId, 'm1');
    expect(jordan.buyerMode, BuyerMode.privacy);
    expect(jordan.privacyMessage, 'Buyer turned off sharing.');
    expect(
      jordan.pendingActions.map((ClientAction a) => a.type),
      containsAll(<ClientActionType>[
        ClientActionType.inquiryResponse,
        ClientActionType.showingRequested,
      ]),
    );
  });

  test('filters search, recently added, and pending actions', () {
    final List<RosterClient> clients = <RosterClient>[
      RosterClient(
        id: '1',
        name: 'Alex Chen',
        email: 'a@x.com',
        phone: '',
        status: ClientUiStatus.active,
        lastActiveTimestamp: now.millisecondsSinceEpoch,
        createdAt: now.subtract(const Duration(days: 2)),
        searches: 8,
        messages: 2,
        activities: const <ClientActivity>[],
        actions: <ClientAction>[
          ClientAction(
            id: 'a1',
            type: ClientActionType.showingRequested,
            description: 'Tour',
            priority: ActionPriority.high,
            status: ActionItemStatus.pending,
            createdAt: now,
          ),
        ],
      ),
      RosterClient(
        id: '2',
        name: 'Jordan',
        email: 'j@x.com',
        phone: '',
        status: ClientUiStatus.invited,
        lastActiveTimestamp: 0,
        createdAt: now.subtract(const Duration(days: 20)),
        searches: 0,
        messages: 0,
        activities: const <ClientActivity>[],
        actions: const <ClientAction>[],
      ),
    ];

    expect(
      ClientRosterQuery.apply(
        clients,
        const ClientListQuery(search: 'alex'),
      ).map((RosterClient c) => c.name),
      <String>['Alex Chen'],
    );
    expect(
      ClientRosterQuery.apply(
        clients,
        const ClientListQuery(recentlyAdded: true),
        now: now,
      ),
      hasLength(1),
    );
    expect(
      ClientRosterQuery.apply(
        clients,
        const ClientListQuery(actionFilter: ActionFilter.showingRequested),
      ).single.id,
      '1',
    );
  });

  test('criteria diff marks added removed and changed', () {
    final List<CriteriaChange> changes = CriteriaDiff.diff(
      <String, dynamic>{'beds': 3, 'city': 'Frisco'},
      <String, dynamic>{'beds': 4, 'city': 'Frisco', 'baths': 2},
    );
    expect(
      changes.map((CriteriaChange c) => '${c.kind.name}:${c.path}'),
      containsAll(<String>['changed:beds', 'added:baths']),
    );
    expect(CriteriaDiff.labelFor('maxPrice'), 'Max Price');
    expect(CriteriaDiff.formatValue(true), 'Yes');
  });
}
