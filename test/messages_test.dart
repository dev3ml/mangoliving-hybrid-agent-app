import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/utils/time_format.dart';
import 'package:mangoliving_agent/features/messages/domain/models/chat_message.dart';
import 'package:mangoliving_agent/features/messages/domain/models/chat_thread.dart';
import 'package:mangoliving_agent/features/messages/presentation/controllers/chat_threads_controller.dart';
import 'package:mangoliving_agent/features/messages/presentation/pages/messages_page.dart';

class _FakeThreadsController extends ChatThreadsController {
  @override
  Future<ChatThreadsState> build() async {
    return const ChatThreadsState(
      threads: <ChatThread>[
        ChatThread(
          agentClientId: 'c1',
          buyerName: 'Maya Chen',
          buyerEmail: 'maya@example.com',
          unreadCount: 4,
          updatedAt: '2026-09-20T10:00:00.000Z',
          lastMessageText: 'See you Sunday',
          lastMessageAt: '2026-09-20T10:00:00.000Z',
          lastSenderRole: 'agent',
        ),
        ChatThread(
          agentClientId: 'c2',
          buyerName: 'Alex',
          buyerEmail: 'alex@example.com',
          unreadCount: 0,
          updatedAt: '2026-09-19T10:00:00.000Z',
          lastMessageText: 'Thanks',
          lastSenderRole: 'buyer',
        ),
      ],
    );
  }
}

void main() {
  test('thread preview prefixes agent messages and caps unread', () {
    const ChatThread thread = ChatThread(
      agentClientId: 'c1',
      buyerName: 'Maya',
      unreadCount: 100,
      updatedAt: '2026-09-20T10:00:00.000Z',
      lastMessageText: 'See you Sunday',
      lastSenderRole: 'agent',
    );
    expect(thread.preview, 'You: See you Sunday');
    expect(TimeFormat.unreadLabel(thread.unreadCount), '99+');
    expect(thread.initials, 'M');
  });

  test('visible threads filter by name or email', () {
    const ChatThreadsState state = ChatThreadsState(
      threads: <ChatThread>[
        ChatThread(
          agentClientId: 'c1',
          buyerName: 'Maya Chen',
          buyerEmail: 'maya@example.com',
          unreadCount: 2,
          updatedAt: '2026-09-20T10:00:00.000Z',
        ),
        ChatThread(
          agentClientId: 'c2',
          buyerName: 'Alex',
          buyerEmail: 'alex@example.com',
          unreadCount: 1,
          updatedAt: '2026-09-19T10:00:00.000Z',
        ),
      ],
      search: 'maya@',
    );
    expect(state.visible.single.buyerName, 'Maya Chen');
    expect(state.unreadTotal, 3);
  });

  test('agent bubbles expose read ticks', () {
    const ChatMessage unread = ChatMessage(
      id: '1',
      agentClientId: 'c1',
      text: 'Hi',
      senderRole: 'agent',
      createdAt: '2026-09-20T10:00:00.000Z',
    );
    const ChatMessage read = ChatMessage(
      id: '2',
      agentClientId: 'c1',
      text: 'Hi',
      senderRole: 'agent',
      createdAt: '2026-09-20T10:00:00.000Z',
      readByBuyerAt: '2026-09-20T10:01:00.000Z',
    );
    expect(unread.isMine, isTrue);
    expect(unread.isReadByBuyer, isFalse);
    expect(read.isReadByBuyer, isTrue);
    expect(
      const ChatMessage(
        id: '3',
        agentClientId: 'c1',
        text: 'gone',
        senderRole: 'buyer',
        createdAt: '2026-09-20T10:00:00.000Z',
        deletedAt: '2026-09-20T10:02:00.000Z',
      ).displayText,
      'This message was deleted',
    );
  });

  test('message time uses clock on the same day', () {
    expect(
      TimeFormat.messageTime(
        '2026-09-20T15:30:00.000',
        DateTime(2026, 9, 20, 18),
      ),
      isNotEmpty,
    );
  });

  testWidgets('Messages list renders threads and empty search copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          chatThreadsControllerProvider.overrideWith(_FakeThreadsController.new),
        ],
        child: const MaterialApp(home: MessagesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maya Chen'), findsOneWidget);
    expect(find.text('You: See you Sunday'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Search clients'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
  });
}
