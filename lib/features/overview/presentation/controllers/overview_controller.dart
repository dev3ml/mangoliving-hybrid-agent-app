import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../data/repositories/overview_repository_impl.dart';
import '../../domain/models/overview_snapshot.dart';
import '../../domain/repositories/overview_repository.dart';

final overviewControllerProvider =
    AsyncNotifierProvider<OverviewController, OverviewSnapshot>(
  OverviewController.new,
);

class OverviewController extends AsyncNotifier<OverviewSnapshot> {
  OverviewRepository get _repo => ref.read(overviewRepositoryProvider);

  @override
  Future<OverviewSnapshot> build() async {
    final OverviewSnapshot snapshot = await _repo.load();
    _syncChrome(snapshot);
    return snapshot;
  }

  Future<void> refresh() async {
    try {
      final OverviewSnapshot next = await _repo.load();
      _syncChrome(next);
      state = AsyncData<OverviewSnapshot>(next);
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<OverviewSnapshot>(error, stackTrace);
      }
    }
  }

  Future<void> markAllNotificationsRead() async {
    final OverviewSnapshot? current = state.valueOrNull;
    if (current == null) return;
    final String iso =
        current.newestNotificationAt ?? DateTime.now().toIso8601String();
    await _repo.markNotificationsRead(iso);
    final OverviewSnapshot next = current.copyWith(
      lastReadAt: DateTime.tryParse(iso) ?? DateTime.now(),
    );
    _syncChrome(next);
    state = AsyncData<OverviewSnapshot>(next);
  }

  Future<void> markNotificationRead(String createdAt) async {
    final OverviewSnapshot? current = state.valueOrNull;
    if (current == null) return;
    final DateTime? created = DateTime.tryParse(createdAt);
    if (created == null) return;
    if (current.lastReadAt != null && !created.isAfter(current.lastReadAt!)) {
      return;
    }
    await _repo.markNotificationsRead(createdAt);
    final OverviewSnapshot next = current.copyWith(lastReadAt: created);
    _syncChrome(next);
    state = AsyncData<OverviewSnapshot>(next);
  }

  void _syncChrome(OverviewSnapshot snapshot) {
    syncDashboardUnread(ref, snapshot.unreadNotificationCount);
    if (snapshot.profile != null) {
      syncDashboardUser(ref, snapshot.profile);
    }
  }
}
