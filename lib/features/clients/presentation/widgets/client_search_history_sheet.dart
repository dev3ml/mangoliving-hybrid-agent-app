import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/criteria_history.dart';
import '../../domain/models/roster_client.dart';
import '../controllers/clients_controller.dart';

Future<void> showClientSearchHistorySheet(
  BuildContext context,
  RosterClient client,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => ClientSearchHistorySheet(client: client),
  );
}

class ClientSearchHistorySheet extends ConsumerStatefulWidget {
  const ClientSearchHistorySheet({super.key, required this.client});

  final RosterClient client;

  @override
  ConsumerState<ClientSearchHistorySheet> createState() =>
      _ClientSearchHistorySheetState();
}

class _ClientSearchHistorySheetState
    extends ConsumerState<ClientSearchHistorySheet> {
  late Future<List<CriteriaHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.client.isSharingHidden
        ? Future<List<CriteriaHistoryEntry>>.value(
            const <CriteriaHistoryEntry>[],
          )
        : ref
            .read(clientsControllerProvider.notifier)
            .loadHistory(widget.client.id);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Search History', style: theme.textTheme.titleLarge),
              Text(
                widget.client.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _body(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (widget.client.isSharingHidden) {
      return Text(
        widget.client.privacyMessage ??
            'Search insights are private. Showing requests are still shared.',
      );
    }
    return FutureBuilder<List<CriteriaHistoryEntry>>(
      future: _future,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<CriteriaHistoryEntry>> snapshot,
      ) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        final List<CriteriaHistoryEntry> entries =
            snapshot.data ?? const <CriteriaHistoryEntry>[];
        if (entries.isEmpty) {
          return const Text('No recent activity');
        }
        final List<CriteriaHistoryEntry> chronological = entries.toList()
          ..sort((CriteriaHistoryEntry a, CriteriaHistoryEntry b) {
            return (a.createdAt ?? '').compareTo(b.createdAt ?? '');
          });
        return ListView.separated(
          itemCount: chronological.length,
          separatorBuilder: (_, _) => const Divider(height: 24),
          itemBuilder: (BuildContext context, int index) {
            final CriteriaHistoryEntry current = chronological[index];
            final CriteriaHistoryEntry? previous =
                index == 0 ? null : chronological[index - 1];
            final List<CriteriaChange> changes = CriteriaDiff.diff(
              previous?.criteria,
              current.criteria,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  TimeFormat.relative(current.createdAt),
                  style: theme.textTheme.labelMedium,
                ),
                if ((current.searchText ?? '').isNotEmpty)
                  Text(current.searchText!),
                if (current.resultCount != null)
                  Text(
                    '${current.resultCount} results',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                if (changes.isEmpty)
                  Text(
                    'No criteria changes',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  ...changes.map(_changeRow),
              ],
            );
          },
        );
      },
    );
  }

  Widget _changeRow(CriteriaChange change) {
    final Color color = switch (change.kind) {
      CriteriaChangeKind.added => AppColors.review,
      CriteriaChangeKind.removed => AppColors.destructive,
      CriteriaChangeKind.changed => AppColors.pending,
    };
    final IconData icon = switch (change.kind) {
      CriteriaChangeKind.added => Icons.add,
      CriteriaChangeKind.removed => Icons.remove,
      CriteriaChangeKind.changed => Icons.edit_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  change.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (change.kind == CriteriaChangeKind.changed)
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: CriteriaDiff.formatValue(change.oldValue),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const TextSpan(text: ' → '),
                        TextSpan(
                          text: CriteriaDiff.formatValue(change.newValue),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    CriteriaDiff.formatValue(
                      change.kind == CriteriaChangeKind.removed
                          ? change.oldValue
                          : change.newValue,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
