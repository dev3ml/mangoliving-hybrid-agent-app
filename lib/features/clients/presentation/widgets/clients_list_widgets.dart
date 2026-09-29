import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/managed_client.dart';
import '../../domain/models/roster_client.dart';

class ClientsPendingBanner extends StatelessWidget {
  const ClientsPendingBanner({
    super.key,
    required this.requests,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final List<ManagedClient> requests;
  final bool Function(String key) isBusy;
  final Future<void> Function(ManagedClient request) onAccept;
  final Future<void> Function(ManagedClient request) onDecline;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.pending.withValues(alpha: 0.12) : AppColors.amberBanner,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.notifications_active_outlined, color: AppColors.pending),
              const SizedBox(width: 8),
              Text(
                'Pending requests (${requests.length})',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'These buyers have asked to add you as their agent. Accept to add them to your client list, or decline to dismiss the request.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...requests.map((ManagedClient request) {
            final bool accepting = isBusy('accept:${request.id}');
            final bool declining = isBusy('decline:${request.id}');
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          request.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (request.email.isNotEmpty)
                          Text(request.email, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: accepting || declining
                        ? null
                        : () => onDecline(request),
                    child: Text(declining ? 'Declining…' : 'Decline'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: accepting || declining
                        ? null
                        : () => onAccept(request),
                    child: Text(accepting ? 'Accepting…' : 'Accept'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ClientsActionChips extends StatelessWidget {
  const ClientsActionChips({
    super.key,
    required this.clients,
    required this.selected,
    required this.onSelected,
  });

  final List<RosterClient> clients;
  final ActionFilter selected;
  final ValueChanged<ActionFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<({ActionFilter filter, String label, int count, Color color})>
        chips = <({ActionFilter filter, String label, int count, Color color})>[
      (
        filter: ActionFilter.hasActions,
        label: 'Total Pending Actions',
        count: ClientRosterQuery.totalPendingActions(clients),
        color: AppColors.pending,
      ),
      (
        filter: ActionFilter.hasActions,
        label: 'Needs Attention',
        count: ClientRosterQuery.needsAttentionCount(clients),
        color: AppColors.attentionPurple,
      ),
      (
        filter: ActionFilter.showingRequested,
        label: 'Showing Requested',
        count: ClientRosterQuery.countByType(
          clients,
          ClientActionType.showingRequested,
        ),
        color: AppColors.showingAction,
      ),
      (
        filter: ActionFilter.needsFollowup,
        label: 'Needs Follow-up',
        count: ClientRosterQuery.countByType(
          clients,
          ClientActionType.needsFollowup,
        ),
        color: AppColors.followup,
      ),
      (
        filter: ActionFilter.inquiryResponse,
        label: 'Respond to Inquiry',
        count: ClientRosterQuery.countByType(
          clients,
          ClientActionType.inquiryResponse,
        ),
        color: AppColors.inquiry,
      ),
      (
        filter: ActionFilter.scheduleCallback,
        label: 'Schedule Callback',
        count: ClientRosterQuery.countByType(
          clients,
          ClientActionType.scheduleCallback,
        ),
        color: AppColors.attentionPurple,
      ),
      (
        filter: ActionFilter.reviewCriteria,
        label: 'Review Criteria',
        count: ClientRosterQuery.countByType(
          clients,
          ClientActionType.reviewCriteria,
        ),
        color: AppColors.review,
      ),
    ];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final chip = chips[index];
          final bool active = selected == chip.filter &&
              (chip.filter != ActionFilter.hasActions || selected == ActionFilter.hasActions);
          return Material(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: active
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: active ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => onSelected(
                selected == chip.filter ? ActionFilter.all : chip.filter,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${chip.count}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: chip.color,
                          ),
                    ),
                    Text(chip.label, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ClientsFilterChips extends StatelessWidget {
  const ClientsFilterChips({
    super.key,
    required this.query,
    required this.filteredCount,
    required this.totalCount,
    required this.onClear,
    required this.onChanged,
  });

  final ClientListQuery query;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onClear;
  final ValueChanged<ClientListQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Showing $filteredCount of $totalCount clients',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (query.hasActiveFilters) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (query.search.trim().isNotEmpty)
                InputChip(
                  label: Text(query.search.trim()),
                  onDeleted: () => onChanged(query.copyWith(search: '')),
                ),
              if (query.status != null)
                InputChip(
                  label: Text(_statusLabel(query.status!)),
                  onDeleted: () => onChanged(query.copyWith(clearStatus: true)),
                ),
              if (query.actionFilter != ActionFilter.all)
                InputChip(
                  label: Text(_actionLabel(query.actionFilter)),
                  onDeleted: () =>
                      onChanged(query.copyWith(actionFilter: ActionFilter.all)),
                ),
              if (query.recentlyAdded)
                InputChip(
                  label: const Text('Recently Added'),
                  onDeleted: () =>
                      onChanged(query.copyWith(recentlyAdded: false)),
                ),
              ActionChip(
                label: const Text('Clear all filters'),
                onPressed: onClear,
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _statusLabel(ClientUiStatus status) {
    return switch (status) {
      ClientUiStatus.revoked => 'Relation Revoked',
      ClientUiStatus.active => 'Active',
      ClientUiStatus.invited => 'Invited',
      ClientUiStatus.declined => 'Declined',
      ClientUiStatus.inactive => 'Inactive',
      ClientUiStatus.paused => 'Paused',
      ClientUiStatus.archived => 'Archived',
    };
  }

  static String _actionLabel(ActionFilter filter) {
    return switch (filter) {
      ActionFilter.hasActions => 'Has Pending Actions',
      ActionFilter.highPriority => 'High Priority',
      ActionFilter.mediumPriority => 'Medium Priority',
      ActionFilter.lowPriority => 'Low Priority',
      ActionFilter.showingRequested => 'Showing Requested',
      ActionFilter.needsFollowup => 'Needs Follow-up',
      ActionFilter.inquiryResponse => 'Respond to Inquiry',
      ActionFilter.scheduleCallback => 'Schedule Callback',
      ActionFilter.reviewCriteria => 'Review Criteria',
      ActionFilter.all => 'All Actions',
    };
  }
}

class ClientRosterCard extends StatelessWidget {
  const ClientRosterCard({
    super.key,
    required this.client,
    required this.onOpen,
    required this.onHistory,
    required this.onResend,
    required this.onDelete,
    required this.onMoveStatus,
  });

  final RosterClient client;
  final VoidCallback onOpen;
  final VoidCallback onHistory;
  final VoidCallback onResend;
  final VoidCallback onDelete;
  final ValueChanged<ClientUiStatus> onMoveStatus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(child: Text(client.initials)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      client.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (client.email.isNotEmpty)
                      Text(client.email, style: theme.textTheme.bodySmall),
                    if (client.phone.isNotEmpty)
                      Text(client.phone, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _StatusBadge(status: client.status),
                        if (client.buyerMode == BuyerMode.sharing)
                          const _ModeBadge(sharing: true),
                        if (client.buyerMode == BuyerMode.privacy)
                          const _ModeBadge(sharing: false),
                        if (client.buyerMode == null)
                          Text(
                            '—',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${client.searches} searches · ${client.messages} messages · ${TimeFormat.lastActiveLabel(client.lastActiveTimestamp)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _ActionCountChip(count: client.pendingActionCount),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (String value) {
                  switch (value) {
                    case 'details':
                      onOpen();
                    case 'history':
                      onHistory();
                    case 'resend':
                      onResend();
                    case 'delete':
                      onDelete();
                    case 'active':
                      onMoveStatus(ClientUiStatus.active);
                    case 'paused':
                      onMoveStatus(ClientUiStatus.paused);
                    case 'archived':
                      onMoveStatus(ClientUiStatus.archived);
                    case 'inactive':
                      onMoveStatus(ClientUiStatus.inactive);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'details',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'history',
                      child: Text('View Search History'),
                    ),
                    if (client.canResendInvite)
                      const PopupMenuItem<String>(
                        value: 'resend',
                        child: Text('Resend Invite'),
                      ),
                    const PopupMenuItem<String>(
                      value: 'active',
                      child: Text('Move to Active'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'paused',
                      child: Text('Move to Paused'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'archived',
                      child: Text('Move to Archived'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'inactive',
                      child: Text('Move to Inactive'),
                    ),
                    if (client.canDelete)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete Client'),
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ClientUiStatus status;

  @override
  Widget build(BuildContext context) {
    final bool destructive =
        status == ClientUiStatus.declined || status == ClientUiStatus.revoked;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        switch (status) {
          ClientUiStatus.revoked => 'Relation Revoked',
          ClientUiStatus.active => 'Active',
          ClientUiStatus.invited => 'Invited',
          ClientUiStatus.declined => 'Declined',
          ClientUiStatus.inactive => 'Inactive',
          ClientUiStatus.paused => 'Paused',
          ClientUiStatus.archived => 'Archived',
        },
      ),
      backgroundColor: destructive
          ? AppColors.destructive.withValues(alpha: 0.12)
          : null,
      labelStyle: TextStyle(
        color: destructive ? AppColors.destructive : null,
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.sharing});

  final bool sharing;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        sharing ? Icons.visibility : Icons.visibility_off,
        size: 14,
        color: sharing ? Colors.white : null,
      ),
      label: Text(sharing ? 'Sharing' : 'Privacy'),
      backgroundColor: sharing ? AppColors.sharing : null,
      labelStyle: TextStyle(color: sharing ? Colors.white : null),
    );
  }
}

class _ActionCountChip extends StatelessWidget {
  const _ActionCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(Icons.check, size: 16),
        label: Text('No Actions'),
      );
    }
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.destructive.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: AppColors.destructive),
      label: Text(count == 1 ? '1 Action' : '$count Actions'),
    );
  }
}

Future<ClientListQuery?> showClientFilterSheet(
  BuildContext context,
  ClientListQuery query,
) {
  return showModalBottomSheet<ClientListQuery>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) => _FilterSheet(query: query),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.query});

  final ClientListQuery query;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ClientListQuery _query;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ClientUiStatus?>(
              initialValue: _query.status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const <DropdownMenuItem<ClientUiStatus?>>[
                DropdownMenuItem<ClientUiStatus?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.active,
                  child: Text('Active'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.invited,
                  child: Text('Invited'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.declined,
                  child: Text('Declined'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.inactive,
                  child: Text('Inactive'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.paused,
                  child: Text('Paused'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.archived,
                  child: Text('Archived'),
                ),
                DropdownMenuItem<ClientUiStatus?>(
                  value: ClientUiStatus.revoked,
                  child: Text('Relation Revoked'),
                ),
              ],
              onChanged: (ClientUiStatus? value) {
                setState(() {
                  _query = value == null
                      ? _query.copyWith(clearStatus: true)
                      : _query.copyWith(status: value);
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<ActionFilter>(
              initialValue: _query.actionFilter,
              decoration: const InputDecoration(labelText: 'Action filter'),
              items: ActionFilter.values
                  .map(
                    (ActionFilter filter) => DropdownMenuItem<ActionFilter>(
                      value: filter,
                      child: Text(ClientsFilterChips._actionLabel(filter)),
                    ),
                  )
                  .toList(),
              onChanged: (ActionFilter? value) {
                if (value == null) return;
                setState(() => _query = _query.copyWith(actionFilter: value));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<SortField>(
              initialValue: _query.sortField,
              decoration: const InputDecoration(labelText: 'Sort'),
              items: const <DropdownMenuItem<SortField>>[
                DropdownMenuItem<SortField>(
                  value: SortField.name,
                  child: Text('Name'),
                ),
                DropdownMenuItem<SortField>(
                  value: SortField.lastActive,
                  child: Text('Last active'),
                ),
                DropdownMenuItem<SortField>(
                  value: SortField.activityLevel,
                  child: Text('Activity level'),
                ),
                DropdownMenuItem<SortField>(
                  value: SortField.pendingActions,
                  child: Text('Pending actions'),
                ),
              ],
              onChanged: (SortField? value) {
                if (value == null) return;
                setState(() => _query = _query.copyWith(sortField: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recently Added'),
              value: _query.recentlyAdded,
              onChanged: (bool value) {
                setState(() => _query = _query.copyWith(recentlyAdded: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sort ascending'),
              value: _query.sortAscending,
              onChanged: (bool value) {
                setState(() => _query = _query.copyWith(sortAscending: value));
              },
            ),
            Text(
              'Activity Level is based on the combined total of each client\'s searches and messages.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_query),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
