import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';

final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, AnalyticsViewData>(
  AnalyticsController.new,
);

final class AnalyticsViewData {
  const AnalyticsViewData({
    required this.clients,
    required this.months,
    this.selectedBuyerId,
    this.overview,
    this.ai,
    this.aiFailed = false,
    this.aiLoading = false,
    this.overviewFailed = false,
  });

  final List<AnalyticsClient> clients;
  final int months;
  final String? selectedBuyerId;
  final AnalyticsOverview? overview;
  final AiSummary? ai;
  final bool aiFailed;
  final bool aiLoading;
  final bool overviewFailed;

  AnalyticsClient? get selected {
    for (final AnalyticsClient client in clients) {
      if (client.id == selectedBuyerId) return client;
    }
    return null;
  }

  bool get sharingDisabled => overview != null && !overview!.analyticsEnabled;

  AnalyticsViewData copyWith({
    List<AnalyticsClient>? clients,
    int? months,
    String? selectedBuyerId,
    AnalyticsOverview? overview,
    bool clearOverview = false,
    AiSummary? ai,
    bool clearAi = false,
    bool? aiFailed,
    bool? aiLoading,
    bool? overviewFailed,
  }) {
    return AnalyticsViewData(
      clients: clients ?? this.clients,
      months: months ?? this.months,
      selectedBuyerId: selectedBuyerId ?? this.selectedBuyerId,
      overview: clearOverview ? null : (overview ?? this.overview),
      ai: clearAi ? null : (ai ?? this.ai),
      aiFailed: aiFailed ?? this.aiFailed,
      aiLoading: aiLoading ?? this.aiLoading,
      overviewFailed: overviewFailed ?? this.overviewFailed,
    );
  }
}

class AnalyticsController extends AsyncNotifier<AnalyticsViewData> {
  AnalyticsRepository get _repo => ref.read(analyticsRepositoryProvider);

  @override
  Future<AnalyticsViewData> build() async {
    final AnalyticsViewData data = await _loadBoard(months: 6);
    _scheduleAi(data);
    return data;
  }

  Future<void> refresh() async {
    final AnalyticsViewData? current = state.valueOrNull;
    try {
      final AnalyticsViewData next = await _loadBoard(
        months: current?.months ?? 6,
        preferredBuyerId: current?.selectedBuyerId,
      );
      state = AsyncData<AnalyticsViewData>(next);
      _scheduleAi(next);
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<AnalyticsViewData>(error, stackTrace);
      }
    }
  }

  Future<void> selectClient(String buyerId) async {
    final AnalyticsViewData? current = state.valueOrNull;
    if (current == null || current.selectedBuyerId == buyerId) return;
    await _reload(current.copyWith(selectedBuyerId: buyerId, clearAi: true));
  }

  Future<void> setMonths(int months) async {
    final AnalyticsViewData? current = state.valueOrNull;
    if (current == null || current.months == months) return;
    await _reload(current.copyWith(months: months, clearAi: true));
  }

  Future<void> _reload(AnalyticsViewData base) async {
    try {
      final AnalyticsViewData next = await _loadBoard(
        months: base.months,
        preferredBuyerId: base.selectedBuyerId,
        clients: base.clients,
      );
      state = AsyncData<AnalyticsViewData>(next);
      _scheduleAi(next);
    } on Object {
      state = AsyncData<AnalyticsViewData>(
        base.copyWith(
          overviewFailed: true,
          aiLoading: false,
          clearOverview: true,
          clearAi: true,
        ),
      );
    }
  }

  Future<AnalyticsViewData> _loadBoard({
    required int months,
    String? preferredBuyerId,
    List<AnalyticsClient>? clients,
  }) async {
    final List<AnalyticsClient> list = clients ?? await _repo.listClients();
    String? selected = preferredBuyerId;
    if (selected == null || !list.any((AnalyticsClient c) => c.id == selected)) {
      selected = list.isEmpty ? null : list.first.id;
    }
    if (selected == null) {
      return AnalyticsViewData(clients: list, months: months);
    }
    try {
      final AnalyticsOverview overview = await _repo.overview(
        buyerId: selected,
        months: months,
      );
      return AnalyticsViewData(
        clients: list,
        months: months,
        selectedBuyerId: selected,
        overview: overview,
        aiLoading: overview.analyticsEnabled,
      );
    } on Object {
      return AnalyticsViewData(
        clients: list,
        months: months,
        selectedBuyerId: selected,
        overviewFailed: true,
      );
    }
  }

  void _scheduleAi(AnalyticsViewData data) {
    if (data.overview?.analyticsEnabled != true || data.selectedBuyerId == null) {
      return;
    }
    final String buyerId = data.selectedBuyerId!;
    final int months = data.months;
    Future<void>(() async {
      try {
        final AiSummary ai = await _repo.aiSummary(
          buyerId: buyerId,
          months: months,
        );
        _applyAi(buyerId: buyerId, months: months, ai: ai, failed: false);
      } on Object {
        _applyAi(buyerId: buyerId, months: months, ai: null, failed: true);
      }
    });
  }

  void _applyAi({
    required String buyerId,
    required int months,
    required AiSummary? ai,
    required bool failed,
  }) {
    final AnalyticsViewData? current = state.valueOrNull;
    if (current == null) return;
    if (current.selectedBuyerId != buyerId || current.months != months) return;
    state = AsyncData<AnalyticsViewData>(
      current.copyWith(
        ai: ai,
        clearAi: ai == null,
        aiFailed: failed,
        aiLoading: false,
      ),
    );
  }
}
