import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/utils/time_format.dart';
import 'package:mangoliving_agent/features/clients/domain/models/managed_client.dart';
import 'package:mangoliving_agent/features/messages/domain/models/chat_thread.dart';
import 'package:mangoliving_agent/features/overview/domain/models/overview_snapshot.dart';
import 'package:mangoliving_agent/features/showings/domain/models/showing_request.dart';

void main() {
  test('greeting buckets by hour', () {
    expect(TimeFormat.greeting(DateTime(2026, 9, 20, 8)), 'Good morning');
    expect(TimeFormat.greeting(DateTime(2026, 9, 20, 14)), 'Good afternoon');
    expect(TimeFormat.greeting(DateTime(2026, 9, 20, 20)), 'Good evening');
  });

  test('attention copy uses item vs items', () {
    expect(
      TimeFormat.attentionCopy(0),
      "You're all caught up. Here's a snapshot of your business.",
    );
    expect(
      TimeFormat.attentionCopy(1),
      'You have 1 item that need your attention today.',
    );
    expect(
      TimeFormat.attentionCopy(2),
      'You have 2 items that need your attention today.',
    );
  });

  test('unread label caps at 99+', () {
    expect(TimeFormat.unreadLabel(0), '');
    expect(TimeFormat.unreadLabel(4), '4');
    expect(TimeFormat.unreadLabel(100), '99+');
  });

  test('snapshot rolls up stats and previews', () {
    final OverviewSnapshot snapshot = OverviewSnapshot(
      clients: const <ManagedClient>[
        ManagedClient(id: '1', name: 'Maya', email: 'm@x.com', status: 'active'),
        ManagedClient(id: '2', name: 'Alex', email: 'a@x.com', status: 'pending'),
        ManagedClient(id: '3', name: 'Sam', email: 's@x.com', status: 'pending'),
      ],
      interestCount: 4,
      showings: <ShowingRequest>[
        const ShowingRequest(
          id: 's1',
          buyerName: 'Maya',
          status: 'pending',
          propertyAddress: '120 Oak St',
        ),
        ShowingRequest(
          id: 's2',
          buyerName: 'Alex',
          status: 'scheduled',
          propertyCity: 'Frisco',
          scheduledAt: DateTime(2026, 9, 21, 14).toIso8601String(),
        ),
      ],
      threads: const <ChatThread>[
        ChatThread(
          agentClientId: 'c1',
          buyerName: 'Maya',
          unreadCount: 3,
          updatedAt: '2026-09-20T10:00:00.000Z',
          lastMessageText: 'See you Sunday',
          lastMessageAt: '2026-09-20T10:00:00.000Z',
          lastSenderRole: 'agent',
        ),
      ],
      notifications: const [],
      lastReadAt: null,
      newestNotificationAt: null,
    );

    expect(snapshot.totalClients, 5);
    expect(snapshot.activeClients, 1);
    expect(snapshot.pendingRequests, 2);
    expect(snapshot.pendingShowings, 1);
    expect(snapshot.unreadMessages, 3);
    expect(snapshot.actionItems, 3);
    expect(snapshot.upcomingShowings, hasLength(1));
    expect(snapshot.recentThreads.single.preview, 'You: See you Sunday');
  });

  test('parses paginated client and thread envelopes', () {
    final ManagedClient client = ManagedClient.fromJson(<String, dynamic>{
      '_id': 'c1',
      'name': '',
      'email': '',
      'status': 'pending',
      'buyerId': <String, dynamic>{
        'firstName': 'Maya',
        'lastName': 'Chen',
        'email': 'maya@example.com',
      },
    });
    expect(client.displayName, 'Maya Chen');
    expect(client.isPending, isTrue);

    final ChatThread thread = ChatThread.fromJson(<String, dynamic>{
      'agentClientId': 'ac1',
      'unreadCount': 2,
      'updatedAt': '2026-09-20T10:00:00.000Z',
      'buyer': <String, dynamic>{
        'firstName': 'Maya',
        'lastName': '',
        'avatarUrl': '',
      },
      'lastMessage': <String, dynamic>{
        'text': 'See you Sunday',
        'createdAt': '2026-09-20T10:00:00.000Z',
        'senderRole': 'agent',
      },
    });
    expect(thread.buyerName, 'Maya');
    expect(thread.preview, 'You: See you Sunday');
    expect(thread.hasLastMessage, isTrue);
  });
}
