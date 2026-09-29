import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../clients/presentation/controllers/clients_controller.dart';
import '../../../overview/presentation/controllers/overview_controller.dart';
import '../../data/repositories/showings_repository_impl.dart';
import '../../domain/models/showing_request.dart';
import '../../domain/repositories/showings_repository.dart';

final showingsInitialFilterProvider = StateProvider<ShowingStatus?>((Ref ref) {
  return null;
});

final showingsControllerProvider =
    AsyncNotifierProvider<ShowingsController, ShowingsViewData>(
  ShowingsController.new,
);

final class ShowingsViewData {
  const ShowingsViewData({
    required this.requests,
    this.filter,
    this.busyIds = const <String>{},
  });

  final List<ShowingRequest> requests;
  final ShowingStatus? filter;
  final Set<String> busyIds;

  ShowingCounts get counts => ShowingCounts.from(requests);

  List<ShowingRequest> get visible {
    if (filter == null) return requests;
    return requests.where((ShowingRequest r) => r.statusEnum == filter).toList();
  }

  bool isBusy(String id) => busyIds.contains(id);

  ShowingsViewData copyWith({
    List<ShowingRequest>? requests,
    ShowingStatus? filter,
    bool clearFilter = false,
    Set<String>? busyIds,
  }) {
    return ShowingsViewData(
      requests: requests ?? this.requests,
      filter: clearFilter ? null : (filter ?? this.filter),
      busyIds: busyIds ?? this.busyIds,
    );
  }
}

class ShowingsController extends AsyncNotifier<ShowingsViewData> {
  ShowingsRepository get _repo => ref.read(showingsRepositoryProvider);

  @override
  Future<ShowingsViewData> build() async {
    final ShowingStatus? initial = ref.read(showingsInitialFilterProvider);
    final List<ShowingRequest> requests = await _repo.list();
    return ShowingsViewData(requests: requests, filter: initial);
  }

  Future<void> refresh() async {
    final ShowingsViewData? current = state.valueOrNull;
    try {
      final List<ShowingRequest> requests = await _repo.list();
      state = AsyncData<ShowingsViewData>(
        ShowingsViewData(
          requests: requests,
          filter: current?.filter ?? ref.read(showingsInitialFilterProvider),
        ),
      );
      await ref.read(overviewControllerProvider.notifier).refresh();
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<ShowingsViewData>(error, stackTrace);
      }
    }
  }

  void setFilter(ShowingStatus? filter) {
    final ShowingsViewData? current = state.valueOrNull;
    if (current == null) return;
    ref.read(showingsInitialFilterProvider.notifier).state = filter;
    state = AsyncData<ShowingsViewData>(
      current.copyWith(filter: filter, clearFilter: filter == null),
    );
  }

  Future<void> schedule({
    required ShowingRequest request,
    required DateTime when,
  }) {
    return _mutate(
      request.id,
      () => _repo.updateStatus(
        id: request.id,
        status: ShowingStatus.scheduled,
        scheduledAt: when.toUtc().toIso8601String(),
      ),
    );
  }

  Future<void> mark({
    required ShowingRequest request,
    required ShowingStatus status,
  }) {
    if (request.statusEnum == status) return Future<void>.value();
    return _mutate(
      request.id,
      () => _repo.updateStatus(id: request.id, status: status),
    );
  }

  Future<void> _mutate(String id, Future<ShowingRequest> Function() run) async {
    final ShowingsViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<ShowingsViewData>(
      current.copyWith(busyIds: <String>{...current.busyIds, id}),
    );
    try {
      final ShowingRequest updated = await run();
      final ShowingsViewData latest = state.valueOrNull ?? current;
      final List<ShowingRequest> next = latest.requests
          .map((ShowingRequest r) => r.id == updated.id ? updated : r)
          .toList();
      state = AsyncData<ShowingsViewData>(
        latest.copyWith(
          requests: next,
          busyIds: <String>{...latest.busyIds}..remove(id),
        ),
      );
      await ref.read(overviewControllerProvider.notifier).refresh();
      await ref.read(clientsControllerProvider.notifier).refresh();
    } on Object {
      final ShowingsViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<ShowingsViewData>(
          latest.copyWith(busyIds: <String>{...latest.busyIds}..remove(id)),
        );
      }
      rethrow;
    }
  }
}
