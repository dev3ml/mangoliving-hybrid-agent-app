import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/offers_repository_impl.dart';
import '../../domain/models/property_action.dart';
import '../../domain/repositories/offers_repository.dart';

final offersControllerProvider =
    AsyncNotifierProvider<OffersController, OffersViewData>(
  OffersController.new,
);

final class OffersViewData {
  const OffersViewData({
    required this.rows,
    this.filter,
    this.busyIds = const <String>{},
  });

  final List<PropertyAction> rows;
  final OfferBoardState? filter;
  final Set<String> busyIds;

  OfferCounts get counts => OfferCounts.from(rows);

  List<PropertyAction> get visible {
    if (filter == null) return rows;
    return rows.where((PropertyAction r) => r.boardState == filter).toList();
  }

  PropertyAction? byId(String id) {
    for (final PropertyAction row in rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  bool isBusy(String id) => busyIds.contains(id);

  OffersViewData copyWith({
    List<PropertyAction>? rows,
    OfferBoardState? filter,
    bool clearFilter = false,
    Set<String>? busyIds,
  }) {
    return OffersViewData(
      rows: rows ?? this.rows,
      filter: clearFilter ? null : (filter ?? this.filter),
      busyIds: busyIds ?? this.busyIds,
    );
  }
}

class OffersController extends AsyncNotifier<OffersViewData> {
  OffersRepository get _repo => ref.read(offersRepositoryProvider);

  @override
  Future<OffersViewData> build() async {
    final List<PropertyAction> rows = await _repo.list();
    return OffersViewData(rows: rows);
  }

  Future<void> refresh() async {
    final OffersViewData? current = state.valueOrNull;
    try {
      final List<PropertyAction> rows = await _repo.list();
      state = AsyncData<OffersViewData>(
        OffersViewData(rows: rows, filter: current?.filter),
      );
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<OffersViewData>(error, stackTrace);
      }
    }
  }

  void setFilter(OfferBoardState? filter) {
    final OffersViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<OffersViewData>(
      current.copyWith(filter: filter, clearFilter: filter == null),
    );
  }

  Future<PropertyAction> sendOffer({
    required String id,
    required OfferPdfForm form,
    String? documentPath,
  }) {
    return _mutate(
      id,
      () => _repo.sendOffer(
        id: id,
        body: form.toWriteBody(),
        documentPath: documentPath,
      ),
    );
  }

  Future<PropertyAction> markAccepted(String id) {
    return _mutate(
      id,
      () => _repo.applyAction(id: id, action: 'offer_accepted'),
    );
  }

  Future<PropertyAction> markRejected(String id) {
    return _mutate(
      id,
      () => _repo.applyAction(id: id, action: 'offer_rejected'),
    );
  }

  Future<PropertyAction> _mutate(
    String id,
    Future<PropertyAction> Function() run,
  ) async {
    final OffersViewData? current = state.valueOrNull;
    if (current == null) {
      return run();
    }
    state = AsyncData<OffersViewData>(
      current.copyWith(busyIds: <String>{...current.busyIds, id}),
    );
    try {
      final PropertyAction updated = await run();
      final OffersViewData latest = state.valueOrNull ?? current;
      final List<PropertyAction> next = latest.rows
          .map((PropertyAction r) => r.id == updated.id ? updated : r)
          .toList();
      if (!next.any((PropertyAction r) => r.id == updated.id)) {
        next.insert(0, updated);
      }
      state = AsyncData<OffersViewData>(
        latest.copyWith(
          rows: next,
          busyIds: <String>{...latest.busyIds}..remove(id),
        ),
      );
      return updated;
    } on Object {
      final OffersViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<OffersViewData>(
          latest.copyWith(busyIds: <String>{...latest.busyIds}..remove(id)),
        );
      }
      rethrow;
    }
  }
}
