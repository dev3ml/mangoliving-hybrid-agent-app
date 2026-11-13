import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/messages/data/chat_socket_service.dart';
import '../../features/messages/domain/models/chat_message.dart';
import '../../features/messages/domain/models/chat_thread.dart';
import '../../features/messages/presentation/controllers/chat_threads_controller.dart';
import '../../features/overview/domain/models/agent_notification.dart';
import '../../features/overview/presentation/controllers/overview_controller.dart';
import 'agent_list_refresh.dart';
import 'push_notification_service.dart';

/// Shows the same kind of banner the buyer app shows for an agent message.
///
/// Chat arrives on the existing socket. Showing requests, open houses, and
/// client requests come from the agent notification feed (and from
/// `agent:notification` once the server emits it). Device push still covers
/// the app when it is backgrounded.
final agentForegroundAlertsProvider = Provider<void>((Ref ref) {
  final PushNotificationService push = ref.read(pushNotificationServiceProvider);
  final ChatSocketService socket = ref.read(chatSocketServiceProvider);
  StreamSubscription<ChatSocketPayload>? messages;
  StreamSubscription<ChatSocketPayload>? agentNotes;
  Timer? timer;
  _ResumeRefresher? resume;
  final Set<String> seen = <String>{};
  var seeded = false;
  var syncing = false;

  Future<void> announceFeed() async {
    if (syncing) return;
    if (!ref.read(isAuthenticatedForPushProvider)) return;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    syncing = true;
    try {
      await refreshAgentLists(ref);
      final snapshot = ref.read(overviewControllerProvider).valueOrNull;
      if (snapshot == null || snapshot.notificationsFailed) return;
      final bool announce = seeded;
      for (final AgentNotification item in snapshot.notifications) {
        if (!seen.add(item.id)) continue;
        if (!announce) continue;
        unawaited(
          push.present(
            dedupeKey: item.id,
            title: item.title,
            body: item.message ?? '',
            payload: <String, String>{
              'type': item.type,
              'notificationId': item.id,
              if (item.link != null && item.link!.isNotEmpty) 'link': item.link!,
            },
          ),
        );
      }
      seeded = true;
    } finally {
      syncing = false;
    }
  }

  void onChat(ChatSocketPayload payload) {
    final ChatMessage message = ChatMessage.fromJson(payload);
    if (message.isMine || message.isDeleted || message.agentClientId.isEmpty) {
      return;
    }
    if (ref.read(activeChatThreadIdProvider) == message.agentClientId) return;
    final List<ChatThread> threads =
        ref.read(chatThreadsControllerProvider).valueOrNull?.threads ??
            const <ChatThread>[];
    String title = 'New message';
    for (final ChatThread thread in threads) {
      if (thread.agentClientId == message.agentClientId &&
          thread.buyerName.trim().isNotEmpty) {
        title = thread.buyerName.trim();
        break;
      }
    }
    final String key = message.id.isEmpty
        ? 'chat:${message.agentClientId}:${message.text}'
        : 'chat:${message.id}';
    unawaited(
      push.present(
        dedupeKey: key,
        title: title,
        body: message.displayText,
        payload: <String, String>{
          'type': 'buyer_chat',
          'agentClientId': message.agentClientId,
          'notificationId': key,
        },
      ),
    );
  }

  void onAgentNote(ChatSocketPayload payload) {
    final String id = payload['id']?.toString() ?? '';
    if (id.isEmpty || !seen.add(id)) return;
    final String type = payload['type']?.toString() ?? 'showing_request';
    unawaited(refreshAgentLists(ref, type: type));
    unawaited(
      push.present(
        dedupeKey: id,
        title: payload['title']?.toString() ?? 'MangoLiving',
        body: payload['message']?.toString() ?? payload['body']?.toString() ?? '',
        payload: <String, String>{
          'type': type,
          'notificationId': id,
          if ((payload['link']?.toString() ?? '').isNotEmpty)
            'link': payload['link'].toString(),
        },
      ),
    );
  }

  void start() {
    messages = socket.onMessage.listen(onChat);
    agentNotes = socket.onAgentNotification.listen(onAgentNote);
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(announceFeed());
    });
    resume = _ResumeRefresher(announceFeed);
    WidgetsBinding.instance.addObserver(resume!);
    unawaited(announceFeed());
  }

  void stop() {
    messages?.cancel();
    agentNotes?.cancel();
    timer?.cancel();
    if (resume != null) {
      WidgetsBinding.instance.removeObserver(resume!);
    }
    messages = null;
    agentNotes = null;
    timer = null;
    resume = null;
    seen.clear();
    seeded = false;
  }

  ref.listen<bool>(isAuthenticatedForPushProvider, (bool? _, bool next) {
    stop();
    if (next) start();
  }, fireImmediately: true);
  ref.onDispose(stop);
});

final class _ResumeRefresher extends WidgetsBindingObserver {
  _ResumeRefresher(this.onResume);

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResume());
    }
  }
}
