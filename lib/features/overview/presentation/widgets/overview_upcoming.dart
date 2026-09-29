import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../showings/domain/models/showing_request.dart';
import '../../domain/models/overview_snapshot.dart';
import 'overview_section_card.dart';

class OverviewUpcoming extends StatelessWidget {
  const OverviewUpcoming({
    super.key,
    required this.snapshot,
    required this.loading,
  });

  final OverviewSnapshot? snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OverviewSectionCard(
      title: 'Upcoming showings',
      icon: Icons.event_outlined,
      trailing: TextButton(
        onPressed: () => StatefulNavigationShell.of(context).goBranch(3),
        child: const Text('View all'),
      ),
      child: loading
          ? const OverviewSkeletonList(count: 2, height: 64)
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (snapshot == null || snapshot!.showingsFailed) {
      return Text(
        'No showings scheduled yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final List<ShowingRequest> rows = snapshot!.upcomingShowings;
    if (rows.isEmpty) {
      return Column(
        children: <Widget>[
          Icon(
            Icons.event_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No showings scheduled yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      children: rows.map((ShowingRequest showing) {
        final DateTime? when = showing.scheduledAtDate?.toLocal();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      when == null ? '—' : TimeFormat.monthShort(when).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      when == null ? '' : '${when.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      showing.buyerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      showing.propertyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      TimeFormat.showingDate(showing.scheduledAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
