import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/property_search_links.dart';

class PropertySearchPage extends StatelessWidget {
  const PropertySearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Search'),
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
            'Search listings on the web, or in the MangoLiving app.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _SearchChoice(
                  leading: Image.asset(
                    'assets/branding/web_favicon.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  title: 'Web',
                  subtitle: 'Open search in the browser',
                  onTap: () => _openWeb(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SearchChoice(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/branding/mango_app_icon.png',
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: 'App',
                  subtitle: 'Open the MangoLiving app',
                  onTap: () => _openApp(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openWeb(BuildContext context) {
    return _launch(
      context,
      PropertySearchLinks.web(EnvConfig.buyerAppUrl),
      'Couldn’t open the browser.',
    );
  }

  Future<void> _openApp(BuildContext context) async {
    final bool opened = await _tryLaunch(PropertySearchLinks.app);
    if (opened || !context.mounted) return;
    final bool android =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    await _launch(
      context,
      PropertySearchLinks.storeFor(android: android),
      'Couldn’t open the MangoLiving app.',
    );
  }

  Future<void> _launch(BuildContext context, Uri uri, String failure) async {
    final bool opened = await _tryLaunch(uri);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

class _SearchChoice extends StatelessWidget {
  const _SearchChoice({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
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
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 96,
                  child: Center(child: leading),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
