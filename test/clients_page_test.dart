import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/clients/data/repositories/clients_repository_impl.dart';
import 'package:mangoliving_agent/features/clients/domain/models/client_conversation.dart';
import 'package:mangoliving_agent/features/clients/domain/models/criteria_history.dart';
import 'package:mangoliving_agent/features/clients/domain/models/managed_client.dart';
import 'package:mangoliving_agent/features/clients/domain/models/roster_client.dart';
import 'package:mangoliving_agent/features/clients/domain/repositories/clients_repository.dart';
import 'package:mangoliving_agent/features/clients/domain/roster_merge.dart';
import 'package:mangoliving_agent/features/clients/presentation/pages/clients_page.dart';

class _FakeClientsRepository implements ClientsRepository {
  @override
  Future<ClientRoster> load() async {
    return ClientRoster(
      pendingRequests: const <ManagedClient>[
        ManagedClient(
          id: 'p1',
          name: 'Maya',
          email: 'maya@example.com',
          status: 'pending',
        ),
      ],
      clients: <RosterClient>[
        RosterClient(
          id: 'c1',
          name: 'Alex Chen',
          email: 'alex@example.com',
          phone: '555-0100',
          status: ClientUiStatus.active,
          lastActiveTimestamp: DateTime(2026, 9, 20).millisecondsSinceEpoch,
          createdAt: DateTime(2026, 9, 1),
          searches: 12,
          messages: 3,
          activities: const <ClientActivity>[],
          actions: const <ClientAction>[],
          buyerMode: BuyerMode.sharing,
          managedClientId: 'm1',
        ),
      ],
    );
  }

  @override
  Future<void> accept(String managedId) async {}

  @override
  Future<ClientConversation?> conversation(String id) async => null;

  @override
  Future<ManagedClient> create({
    required String email,
    String? name,
    String? phone,
    bool sendInvitation = true,
  }) async {
    return ManagedClient(id: 'n1', name: name ?? '', email: email, status: 'invited');
  }

  @override
  Future<List<CriteriaHistoryEntry>> criteriaHistory(String buyerId) async {
    return const <CriteriaHistoryEntry>[];
  }

  @override
  Future<void> decline(String managedId) async {}

  @override
  Future<void> delete(String managedId) async {}

  @override
  Future<void> resendInvite(String managedId) async {}
}

void main() {
  testWidgets('Clients list shows pending banner and roster card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clientsRepositoryProvider.overrideWith(
            (Ref ref) => _FakeClientsRepository(),
          ),
        ],
        child: const MaterialApp(home: ClientsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending requests (1)'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Alex Chen'), findsOneWidget);
    expect(find.text('Sharing'), findsOneWidget);
    expect(find.text('Search by name...'), findsOneWidget);
    expect(find.text('No clients found'), findsNothing);
  });
}
