import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/domain/models/agent_user.dart';
import '../../../clients/domain/models/managed_client.dart';
import '../../../messages/domain/models/chat_thread.dart';
import '../../../showings/data/repositories/showings_repository_impl.dart';
import '../../../showings/domain/models/showing_request.dart';
import '../../../showings/domain/repositories/showings_repository.dart';
import '../../domain/models/agent_notification.dart';
import '../../domain/models/overview_snapshot.dart';
import '../../domain/repositories/overview_repository.dart';
import '../datasources/overview_remote_datasource.dart';

final overviewRepositoryProvider = Provider<OverviewRepository>((Ref ref) {
  return OverviewRepositoryImpl(
    remote: OverviewRemoteDataSource(ref.watch(dioProvider)),
    storage: ref.watch(secureStorageProvider),
    showings: ref.watch(showingsRepositoryProvider),
  );
});

final class OverviewRepositoryImpl implements OverviewRepository {
  OverviewRepositoryImpl({
    required this._remote,
    required this._storage,
    required this._showings,
  });

  final OverviewRemoteDataSource _remote;
  final SecureStorageService _storage;
  final ShowingsRepository _showings;

  @override
  Future<OverviewSnapshot> load() async {
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      _try(_remote.listClients(), const <ManagedClient>[]),
      _try(_remote.interestCount(), 0),
      _try(_showings.list(), const <ShowingRequest>[]),
      _try(_remote.listThreads(), const <ChatThread>[]),
      _try(
        _remote.listNotifications(),
        (list: const <AgentNotification>[], newestAt: null),
      ),
      _try(_remote.getProfile(), null),
    ]);

    final FetchSlice<List<ManagedClient>> clients =
        results[0] as FetchSlice<List<ManagedClient>>;
    final FetchSlice<int> interests = results[1] as FetchSlice<int>;
    final FetchSlice<List<ShowingRequest>> showings =
        results[2] as FetchSlice<List<ShowingRequest>>;
    final FetchSlice<List<ChatThread>> threads =
        results[3] as FetchSlice<List<ChatThread>>;
    final FetchSlice<({List<AgentNotification> list, String? newestAt})> notes =
        results[4]
            as FetchSlice<({List<AgentNotification> list, String? newestAt})>;
    final FetchSlice<AgentUser?> profile = results[5] as FetchSlice<AgentUser?>;

    return OverviewSnapshot(
      clients: clients.value,
      interestCount: interests.value,
      showings: showings.value,
      threads: threads.value,
      notifications: notes.value.list,
      newestNotificationAt: notes.value.newestAt,
      lastReadAt: await lastReadAt(),
      profile: profile.value,
      clientsFailed: clients.failed,
      showingsFailed: showings.failed,
      threadsFailed: threads.failed,
      notificationsFailed: notes.failed,
    );
  }

  @override
  Future<void> markNotificationsRead(String iso) {
    return _storage.saveNotificationsLastReadAt(iso);
  }

  @override
  Future<DateTime?> lastReadAt() async {
    final String? iso = await _storage.getNotificationsLastReadAt();
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  Future<FetchSlice<T>> _try<T>(Future<T> future, T fallback) async {
    try {
      return FetchSlice<T>(await future);
    } on Object {
      return FetchSlice<T>(fallback, failed: true);
    }
  }
}
