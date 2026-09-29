import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';

/// Temporary screen until the matching `docs/agent-mobile` spec is implemented.
class SpecPlaceholderPage extends StatelessWidget {
  const SpecPlaceholderPage({
    super.key,
    required this.title,
    required this.specPath,
    this.subtitle,
  });

  final String title;
  final String specPath;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: DashboardAppBarActions.of(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              subtitle ?? 'This screen will follow the agent mobile spec.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              specPath,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
