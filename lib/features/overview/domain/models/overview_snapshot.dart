import '../../../auth/domain/models/agent_user.dart';
import '../../../clients/domain/models/managed_client.dart';
import '../../../messages/domain/models/chat_thread.dart';
import '../../../showings/domain/models/showing_request.dart';
import 'agent_notification.dart';

/// Aggregated Home-tab payload. Per-slice [failed] flags match spec §2.10.
final class OverviewSnapshot {
  const OverviewSnapshot({
    required this.clients,
    required this.interestCount,
    required this.showings,
    required this.threads,
    required this.notifications,
    required this.lastReadAt,
    required this.newestNotificationAt,
    this.profile,
    this.clientsFailed = false,
    this.showingsFailed = false,
    this.threadsFailed = false,
    this.notificationsFailed = false,
  });

  final List<ManagedClient> clients;
  final int interestCount;
  final List<ShowingRequest> showings;
  final List<ChatThread> threads;
  final List<AgentNotification> notifications;
  final DateTime? lastReadAt;
  final String? newestNotificationAt;
  final AgentUser? profile;
  final bool clientsFailed;
  final bool showingsFailed;
  final bool threadsFailed;
  final bool notificationsFailed;

  int get activeClients =>
      clients.where((ManagedClient c) => c.isActive).length;

  int get pendingRequests =>
      clients.where((ManagedClient c) => c.isPending).length;

  int get totalClients => activeClients + interestCount;

  int get pendingShowings =>
      showings.where((ShowingRequest s) => s.isPending).length;

  int get unreadMessages =>
      threads.fold<int>(0, (int sum, ChatThread t) => sum + t.unreadCount);

  int get actionItems => pendingRequests + pendingShowings;

  List<ManagedClient> get pendingRequestPreview =>
      clients.where((ManagedClient c) => c.isPending).take(3).toList();

  List<ShowingRequest> get pendingShowingPreview =>
      showings.where((ShowingRequest s) => s.isPending).take(3).toList();

  List<ShowingRequest> get upcomingShowings {
    final List<ShowingRequest> next = showings
        .where((ShowingRequest s) => s.isScheduled)
        .toList()
      ..sort((ShowingRequest a, ShowingRequest b) {
        final DateTime? left = a.scheduledAtDate;
        final DateTime? right = b.scheduledAtDate;
        if (left == null || right == null) return 0;
        return left.compareTo(right);
      });
    return next.take(4).toList();
  }

  List<ChatThread> get recentThreads {
    final List<ChatThread> next = threads
        .where((ChatThread t) => t.hasLastMessage)
        .toList()
      ..sort((ChatThread a, ChatThread b) {
        final DateTime? left = DateTime.tryParse(a.sortAt);
        final DateTime? right = DateTime.tryParse(b.sortAt);
        if (left == null || right == null) return 0;
        return right.compareTo(left);
      });
    return next.take(5).toList();
  }

  int get unreadNotificationCount => notifications
      .where((AgentNotification n) => n.isUnread(lastReadAt))
      .length;

  OverviewSnapshot copyWith({
    DateTime? lastReadAt,
    String? newestNotificationAt,
  }) {
    return OverviewSnapshot(
      clients: clients,
      interestCount: interestCount,
      showings: showings,
      threads: threads,
      notifications: notifications,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      newestNotificationAt: newestNotificationAt ?? this.newestNotificationAt,
      profile: profile,
      clientsFailed: clientsFailed,
      showingsFailed: showingsFailed,
      threadsFailed: threadsFailed,
      notificationsFailed: notificationsFailed,
    );
  }
}

final class FetchSlice<T> {
  const FetchSlice(this.value, {this.failed = false});

  final T value;
  final bool failed;
}
