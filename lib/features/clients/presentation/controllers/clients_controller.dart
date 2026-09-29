import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../overview/presentation/controllers/overview_controller.dart';
import '../../data/repositories/clients_repository_impl.dart';
import '../../domain/models/client_conversation.dart';
import '../../domain/models/criteria_history.dart';
import '../../domain/models/managed_client.dart';
import '../../domain/models/roster_client.dart';
import '../../domain/repositories/clients_repository.dart';
import '../../domain/roster_merge.dart';

final openAddClientProvider = StateProvider<bool>((Ref ref) => false);

final clientsControllerProvider =
    AsyncNotifierProvider<ClientsController, ClientsViewData>(
  ClientsController.new,
);

final class ClientsViewData {
  const ClientsViewData({
    required this.roster,
    this.query = const ClientListQuery(),
    this.inFlight = const <String>{},
  });

  final ClientRoster roster;
  final ClientListQuery query;
  final Set<String> inFlight;

  List<RosterClient> get visible =>
      ClientRosterQuery.apply(roster.clients, query);

  List<ManagedClient> get pendingRequests => roster.pendingRequests;

  int get totalCount => roster.clients.length;

  bool isBusy(String key) => inFlight.contains(key);

  ClientsViewData copyWith({
    ClientRoster? roster,
    ClientListQuery? query,
    Set<String>? inFlight,
  }) {
    return ClientsViewData(
      roster: roster ?? this.roster,
      query: query ?? this.query,
      inFlight: inFlight ?? this.inFlight,
    );
  }
}

class ClientsController extends AsyncNotifier<ClientsViewData> {
  ClientsRepository get _repo => ref.read(clientsRepositoryProvider);

  @override
  Future<ClientsViewData> build() async {
    final ClientRoster roster = await _repo.load();
    return ClientsViewData(roster: roster);
  }

  Future<void> refresh() async {
    final ClientListQuery query =
        state.valueOrNull?.query ?? const ClientListQuery();
    try {
      final ClientRoster roster = await _repo.load();
      state = AsyncData<ClientsViewData>(
        ClientsViewData(roster: roster, query: query),
      );
      await ref.read(overviewControllerProvider.notifier).refresh();
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<ClientsViewData>(error, stackTrace);
      }
    }
  }

  void setQuery(ClientListQuery query) {
    final ClientsViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<ClientsViewData>(current.copyWith(query: query));
  }

  Future<void> accept(ManagedClient request) {
    return _mutate('accept:${request.id}', () => _repo.accept(request.id));
  }

  Future<void> decline(ManagedClient request) {
    return _mutate('decline:${request.id}', () => _repo.decline(request.id));
  }

  Future<void> create({
    required String email,
    String? name,
    String? phone,
    bool sendInvitation = true,
  }) async {
    await _repo.create(
      email: email,
      name: name,
      phone: phone,
      sendInvitation: sendInvitation,
    );
    await refresh();
  }

  Future<void> resendInvite(RosterClient client) async {
    final String? id = client.managedClientId;
    if (id == null) return;
    await _mutate('invite:$id', () => _repo.resendInvite(id));
  }

  Future<void> delete(RosterClient client) async {
    final String? id = client.managedClientId;
    if (id == null) return;
    await _mutate('delete:$id', () => _repo.delete(id));
  }

  void markActionComplete(String clientId, String actionId) {
    final ClientsViewData? current = state.valueOrNull;
    if (current == null) return;
    final List<RosterClient> next = current.roster.clients.map((RosterClient c) {
      if (c.id != clientId) return c;
      return c.copyWith(
        actions: c.actions
            .map(
              (ClientAction a) => a.id == actionId
                  ? a.copyWith(status: ActionItemStatus.completed)
                  : a,
            )
            .toList(),
      );
    }).toList();
    state = AsyncData<ClientsViewData>(
      current.copyWith(
        roster: ClientRoster(
          clients: next,
          pendingRequests: current.roster.pendingRequests,
        ),
      ),
    );
  }

  void moveStatus(String clientId, ClientUiStatus status) {
    final ClientsViewData? current = state.valueOrNull;
    if (current == null) return;
    final DateTime now = DateTime.now();
    final List<RosterClient> next = current.roster.clients.map((RosterClient c) {
      if (c.id != clientId) return c;
      return c.copyWith(
        status: status,
        pausedAt: status == ClientUiStatus.paused ? now : c.pausedAt,
        archivedAt: status == ClientUiStatus.archived ? now : c.archivedAt,
      );
    }).toList();
    state = AsyncData<ClientsViewData>(
      current.copyWith(
        roster: ClientRoster(
          clients: next,
          pendingRequests: current.roster.pendingRequests,
        ),
      ),
    );
  }

  Future<ClientConversation?> loadConversation(String id) {
    return _repo.conversation(id);
  }

  Future<List<CriteriaHistoryEntry>> loadHistory(String buyerId) {
    return _repo.criteriaHistory(buyerId);
  }

  Future<void> _mutate(String key, Future<void> Function() run) async {
    final ClientsViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<ClientsViewData>(
      current.copyWith(inFlight: <String>{...current.inFlight, key}),
    );
    try {
      await run();
      await refresh();
    } on Object {
      final ClientsViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<ClientsViewData>(
          latest.copyWith(
            inFlight: <String>{...latest.inFlight}..remove(key),
          ),
        );
      }
      rethrow;
    }
  }
}
