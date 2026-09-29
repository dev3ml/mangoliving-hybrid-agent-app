import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/auth/domain/models/agent_user.dart';
import 'package:mangoliving_agent/features/clients/domain/models/managed_client.dart';
import 'package:mangoliving_agent/features/messages/domain/models/chat_thread.dart';
import 'package:mangoliving_agent/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:mangoliving_agent/features/overview/domain/models/overview_snapshot.dart';
import 'package:mangoliving_agent/features/overview/domain/repositories/overview_repository.dart';
import 'package:mangoliving_agent/features/overview/presentation/pages/overview_page.dart';
import 'package:mangoliving_agent/features/showings/domain/models/showing_request.dart';

class _FakeOverviewRepository implements OverviewRepository {
  @override
  Future<OverviewSnapshot> load() async {
    return OverviewSnapshot(
      clients: const <ManagedClient>[
        ManagedClient(
          id: '1',
          name: 'Maya',
          email: 'maya@example.com',
          status: 'pending',
        ),
      ],
      interestCount: 2,
      showings: <ShowingRequest>[
        ShowingRequest(
          id: 's2',
          buyerName: 'Alex',
          status: 'scheduled',
          propertyAddress: '120 Oak St',
          scheduledAt: DateTime(2026, 9, 21, 14).toIso8601String(),
        ),
      ],
      threads: const <ChatThread>[
        ChatThread(
          agentClientId: 'c1',
          buyerName: 'Maya',
          unreadCount: 4,
          updatedAt: '2026-09-20T10:00:00.000Z',
          lastMessageText: 'See you Sunday',
          lastMessageAt: '2026-09-20T10:00:00.000Z',
          lastSenderRole: 'agent',
        ),
      ],
      notifications: const [],
      lastReadAt: null,
      newestNotificationAt: null,
      profile: const AgentUser(
        id: 'a1',
        email: 'agent@example.com',
        firstName: 'Priya',
      ),
    );
  }

  @override
  Future<DateTime?> lastReadAt() async => null;

  @override
  Future<void> markNotificationsRead(String iso) async {}
}

void main() {
  testWidgets('Overview renders spec sections and copy', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          overviewRepositoryProvider.overrideWith(
            (Ref ref) => _FakeOverviewRepository(),
          ),
        ],
        child: const MaterialApp(home: OverviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Priya'), findsOneWidget);
    expect(find.text('Add a client'), findsOneWidget);
    expect(find.text('Total clients'), findsOneWidget);
    expect(find.text('Pending requests'), findsOneWidget);
    expect(find.text('Showing requests'), findsOneWidget);
    expect(find.text('Unread messages'), findsOneWidget);
    expect(find.text('Needs your attention'), findsOneWidget);
    expect(find.text('wants to connect with you'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Upcoming showings'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Recent conversations'), findsOneWidget);
    expect(find.text('You: See you Sunday'), findsOneWidget);
    expect(find.text('Want a deeper look at client engagement?'), findsOneWidget);
    expect(find.text('Open analytics'), findsOneWidget);
    expect(find.text('Search properties'), findsNothing);
  });
}
