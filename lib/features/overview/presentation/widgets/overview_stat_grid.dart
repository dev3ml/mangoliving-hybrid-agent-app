import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/overview_snapshot.dart';

class OverviewStatGrid extends StatelessWidget {
  const OverviewStatGrid({
    super.key,
    required this.snapshot,
    required this.loading,
  });

  final OverviewSnapshot? snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.45,
      children: <Widget>[
        _StatCard(
          label: 'Total clients',
          value: snapshot?.totalClients ?? 0,
          hint: snapshot == null
              ? ''
              : '${snapshot!.activeClients} active · ${snapshot!.interestCount} interested',
          color: AppColors.clients,
          icon: Icons.people_outline,
          loading: loading,
          onTap: () => StatefulNavigationShell.of(context).goBranch(1),
        ),
        _StatCard(
          label: 'Pending requests',
          value: snapshot?.pendingRequests ?? 0,
          hint: (snapshot?.pendingRequests ?? 0) > 0
              ? 'Awaiting your response'
              : 'No new requests',
          color: AppColors.pending,
          icon: Icons.person_add_alt_1_outlined,
          loading: loading,
          onTap: () => StatefulNavigationShell.of(context).goBranch(1),
        ),
        _StatCard(
          label: 'Showing requests',
          value: snapshot?.pendingShowings ?? 0,
          hint: (snapshot?.pendingShowings ?? 0) > 0
              ? 'Need scheduling'
              : 'Nothing pending',
          color: AppColors.showings,
          icon: Icons.calendar_today_outlined,
          loading: loading,
          onTap: () => StatefulNavigationShell.of(context).goBranch(3),
        ),
        _StatCard(
          label: 'Unread messages',
          value: snapshot?.unreadMessages ?? 0,
          hint: (snapshot?.unreadMessages ?? 0) > 0
              ? 'New from your clients'
              : 'Inbox is clear',
          color: AppColors.messages,
          icon: Icons.chat_bubble_outline,
          loading: loading,
          onTap: () => StatefulNavigationShell.of(context).goBranch(2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final int value;
  final String hint;
  final Color color;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                ],
              ),
              const Spacer(),
              if (loading)
                Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                Text(
                  '$value',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
