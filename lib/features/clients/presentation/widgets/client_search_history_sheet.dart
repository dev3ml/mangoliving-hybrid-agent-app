import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/criteria_history.dart';
import '../../domain/models/roster_client.dart';
import '../controllers/clients_controller.dart';

Future<void> showClientSearchHistorySheet(
  BuildContext context,
  RosterClient client,
) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => ClientSearchHistorySheet(client: client),
    ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.client.name,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
            Expanded(child: _body(theme)),
          ],
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
          return const AppSkeletonPage(count: 4);
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        final List<CriteriaHistoryEntry> entries =
            snapshot.data ?? const <CriteriaHistoryEntry>[];
        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'No recent activity',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        final List<CriteriaHistoryEntry> chronological = entries.toList()
          ..sort((CriteriaHistoryEntry a, CriteriaHistoryEntry b) {
            return (a.createdAt ?? '').compareTo(b.createdAt ?? '');
          });
        final bool light = theme.brightness == Brightness.light;
        return ListView.separated(
          itemCount: chronological.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final CriteriaHistoryEntry current = chronological[index];
            final CriteriaHistoryEntry? previous =
                index == 0 ? null : chronological[index - 1];
            final List<CriteriaChange> changes = CriteriaDiff.diff(
              previous?.criteria,
              current.criteria,
            );
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: light ? Colors.white : const Color(0xFF241C18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    TimeFormat.relative(current.createdAt),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((current.searchText ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      current.searchText!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (current.resultCount != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      '${current.resultCount} results',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (changes.isEmpty)
                    Text(
                      'No criteria changes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    )
                  else
                    ...changes.map(_changeRow),
                ],
              ),
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
