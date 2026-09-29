import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../auth/domain/models/agent_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../clients/presentation/controllers/clients_controller.dart';
import '../../domain/models/overview_snapshot.dart';
import '../controllers/overview_controller.dart';
import '../widgets/overview_attention.dart';
import '../widgets/overview_conversations.dart';
import '../widgets/overview_stat_grid.dart';
import '../widgets/overview_upcoming.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OverviewSnapshot> async =
        ref.watch(overviewControllerProvider);
    final OverviewSnapshot? snapshot = async.valueOrNull;
    final bool loading = async.isLoading && snapshot == null;
    final AgentUser? user =
        snapshot?.profile ?? ref.watch(authControllerProvider).valueOrNull?.user;
    final String name = user?.firstDisplayName ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: DashboardAppBarActions.of(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(overviewControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: <Widget>[
            _WelcomeBanner(
              name: name,
              actionItems: snapshot?.actionItems ?? 0,
              onAddClient: () {
                ref.read(openAddClientProvider.notifier).state = true;
                StatefulNavigationShell.of(context).goBranch(1);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            OverviewStatGrid(snapshot: snapshot, loading: loading),
            const SizedBox(height: AppSpacing.md),
            OverviewAttention(snapshot: snapshot, loading: loading),
            const SizedBox(height: AppSpacing.md),
            OverviewUpcoming(snapshot: snapshot, loading: loading),
            const SizedBox(height: AppSpacing.md),
            OverviewConversations(snapshot: snapshot, loading: loading),
            const SizedBox(height: AppSpacing.md),
            const _AnalyticsCta(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.name,
    required this.actionItems,
    required this.onAddClient,
  });

  final String name;
  final int actionItems;
  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            TimeFormat.todayLabel(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${TimeFormat.greeting()}, $name',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TimeFormat.attentionCopy(actionItems),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAddClient,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add a client'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCta extends StatelessWidget {
  const _AnalyticsCta();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: theme.colorScheme.outlineVariant,
        radius: AppRadius.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.insights_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Want a deeper look at client engagement?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Track searches, favorites and showing trends per client.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.analytics),
              child: const Text('Open analytics'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);
    const double dash = 5;
    const double gap = 3;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
