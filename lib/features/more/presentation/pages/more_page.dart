import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: DashboardAppBarActions.of(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: <Widget>[
          Text(
            'Tools and account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MoreCard(
            icon: Icons.description_outlined,
            color: AppColors.primary,
            title: 'Offers',
            subtitle: 'Prepare and send buyer offers',
            onTap: () => context.push(AppRoutes.offers),
          ),
          _MoreCard(
            icon: Icons.search,
            color: AppColors.clients,
            title: 'Property Search',
            subtitle: 'Open search on the web or in the app',
            onTap: () => context.push(AppRoutes.propertySearch),
          ),
          _MoreCard(
            icon: Icons.insights_outlined,
            color: AppColors.showings,
            title: 'Analytics',
            subtitle: 'Client search insights',
            onTap: () => context.push(AppRoutes.analytics),
          ),
          _MoreCard(
            icon: Icons.person_outline,
            color: AppColors.messages,
            title: 'Account',
            subtitle: 'Profile and public page',
            onTap: () => context.push(AppRoutes.account),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MoreCard(
            icon: Icons.logout,
            color: colors.error,
            title: 'Log out',
            subtitle: 'Sign out of this device',
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool light = theme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: light ? Colors.white : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
