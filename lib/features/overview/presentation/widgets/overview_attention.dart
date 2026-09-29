import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../clients/domain/models/managed_client.dart';
import '../../../showings/domain/models/showing_request.dart';
import '../../../showings/presentation/controllers/showings_controller.dart';
import '../../domain/models/overview_snapshot.dart';
import 'overview_section_card.dart';

class OverviewAttention extends StatelessWidget {
  const OverviewAttention({
    super.key,
    required this.snapshot,
    required this.loading,
  });

  final OverviewSnapshot? snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return OverviewSectionCard(
      title: 'Needs your attention',
      icon: Icons.schedule,
      child: loading
          ? const OverviewSkeletonList(count: 3)
          : _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (snapshot == null ||
        (snapshot!.clientsFailed && snapshot!.showingsFailed)) {
      return const SizedBox.shrink();
    }
    final List<ManagedClient> requests = snapshot!.pendingRequestPreview;
    final List<ShowingRequest> showings = snapshot!.pendingShowingPreview;
    if (requests.isEmpty && showings.isEmpty) {
      return Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.messages.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppColors.messages),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text("You're all caught up", style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'New client and showing requests will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        ...requests.map((ManagedClient client) {
          return _AttentionRow(
            icon: Icons.person_add_alt_1_outlined,
            color: AppColors.pending,
            title: client.displayName,
            subtitle: 'wants to connect with you',
            badge: 'Review',
            onTap: (BuildContext context) =>
                StatefulNavigationShell.of(context).goBranch(1),
          );
        }),
        ...showings.map((ShowingRequest showing) {
          return _AttentionRow(
            icon: Icons.calendar_today_outlined,
            color: AppColors.showings,
            title: '${showing.buyerName} requested a showing',
            subtitle: showing.propertyLabel,
            badge: 'Schedule',
            onTap: (BuildContext context) {
              ProviderScope.containerOf(context)
                  .read(showingsInitialFilterProvider.notifier)
                  .state = ShowingStatus.pending;
              StatefulNavigationShell.of(context).goBranch(3);
            },
          );
        }),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: () => onTap(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Chip(
                  label: Text(badge),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

