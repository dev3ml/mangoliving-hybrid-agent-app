import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/models/managed_client.dart';
import '../../domain/models/roster_client.dart';
import '../controllers/clients_controller.dart';
import '../widgets/add_client_sheet.dart';
import '../widgets/client_details_sheet.dart';
import '../widgets/client_search_history_sheet.dart';
import '../widgets/clients_list_widgets.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final ClientsViewData? data = ref.read(clientsControllerProvider).valueOrNull;
    if (data == null) return;
    if (data.query.search == _search.text) return;
    ref
        .read(clientsControllerProvider.notifier)
        .setQuery(data.query.copyWith(search: _search.text));
  }

  Future<void> _openAdd() => showAddClientSheet(context);

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(openAddClientProvider, (bool? previous, bool next) {
      if (!next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(openAddClientProvider.notifier).state = false;
        _openAdd();
      });
    });

    final AsyncValue<ClientsViewData> async = ref.watch(clientsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: DashboardAppBarActions.of(
          extra: <Widget>[
            IconButton(
              tooltip: 'Add Client',
              onPressed: _openAdd,
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(clientsControllerProvider.notifier).refresh(),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: Text('Loading clients…')),
          error: (Object error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text(error.toString()),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(clientsControllerProvider.notifier).refresh(),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (ClientsViewData view) => _list(view),
        ),
      ),
    );
  }

  Widget _list(ClientsViewData view) {
    final List<RosterClient> visible = view.visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Text(
          'Manage your client relationships and track their activity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClientsPendingBanner(
          requests: view.pendingRequests,
          isBusy: view.isBusy,
          onAccept: _accept,
          onDecline: _decline,
        ),
        ClientsActionChips(
          clients: view.roster.clients,
          selected: view.query.actionFilter,
          onSelected: (ActionFilter filter) {
            ref
                .read(clientsControllerProvider.notifier)
                .setQuery(view.query.copyWith(actionFilter: filter));
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: AppSearchField(
                controller: _search,
                hintText: 'Search by name...',
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Filters',
              onPressed: () async {
                final ClientListQuery? next =
                    await showClientFilterSheet(context, view.query);
                if (next == null || !mounted) return;
                ref.read(clientsControllerProvider.notifier).setQuery(next);
                if (_search.text != next.search) {
                  _search.text = next.search;
                }
              },
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClientsFilterChips(
          query: view.query,
          filteredCount: visible.length,
          totalCount: view.totalCount,
          onClear: () {
            _search.clear();
            ref
                .read(clientsControllerProvider.notifier)
                .setQuery(const ClientListQuery());
          },
          onChanged: (ClientListQuery query) {
            if (query.search != _search.text) {
              _search.text = query.search;
            }
            ref.read(clientsControllerProvider.notifier).setQuery(query);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          _EmptyState(
            hasSearch: view.query.hasActiveFilters,
            onAdd: _openAdd,
          )
        else
          ...visible.map((RosterClient client) {
            return ClientRosterCard(
              client: client,
              onOpen: () => showClientDetailsSheet(context, client),
              onHistory: () => showClientSearchHistorySheet(context, client),
              onResend: () => _resend(client),
              onDelete: () => _confirmDelete(client),
              onMoveStatus: (ClientUiStatus status) {
                ref
                    .read(clientsControllerProvider.notifier)
                    .moveStatus(client.id, status);
              },
            );
          }),
      ],
    );
  }

  Future<void> _accept(ManagedClient request) async {
    try {
      await ref.read(clientsControllerProvider.notifier).accept(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.displayName} added to your clients')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _decline(ManagedClient request) async {
    try {
      await ref.read(clientsControllerProvider.notifier).decline(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _resend(RosterClient client) async {
    try {
      await ref.read(clientsControllerProvider.notifier).resendInvite(client);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to ${client.email}')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _confirmDelete(RosterClient client) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Client'),
          content: Text('Remove ${client.name} from your list?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Client'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(clientsControllerProvider.notifier).delete(client);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${client.name} removed')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.onAdd});

  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (hasSearch) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: Text('Try adjusting your search query')),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          Text('No clients found', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Add your first client to get started'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Client'),
          ),
        ],
      ),
    );
  }
}
