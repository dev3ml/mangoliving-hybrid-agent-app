import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/account_controller.dart';
import '../widgets/account_sections.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AccountViewData> async = ref.watch(accountControllerProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          actions: DashboardAppBarActions.of(
            extra: <Widget>[
              if (async.valueOrNull?.isDirty == true) ...<Widget>[
                TextButton(
                  onPressed: async.valueOrNull?.busy == true
                      ? null
                      : () => ref
                          .read(accountControllerProvider.notifier)
                          .cancel(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: async.valueOrNull?.busy == true
                      ? null
                      : () => _save(context, ref),
                  child: Text(
                    async.valueOrNull?.saving == true ? 'Saving…' : 'Save',
                  ),
                ),
              ],
              PopupMenuButton<String>(
                onSelected: (String value) async {
                  if (value == 'logout') {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Log out'),
                  ),
                ],
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Widget>[
              Tab(text: 'Profile'),
              Tab(text: 'Media'),
              Tab(text: 'Brokerage'),
              Tab(text: 'Public Profile'),
              Tab(text: 'Account'),
            ],
          ),
        ),
        body: async.when(
          skipLoadingOnReload: true,
          loading: () => const _AccountSkeleton(),
          error: (Object error, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text(
                'Failed to load profile.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString()),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(accountControllerProvider.notifier).refresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
          data: (AccountViewData view) {
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: AccountCompletionHeader(view: view),
                ),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      AccountProfileSection(view: view),
                      AccountMediaSection(view: view),
                      AccountBrokerageSection(view: view),
                      AccountPublicSection(view: view),
                      AccountSecuritySection(view: view),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(accountControllerProvider.notifier).save();
      if (context.mounted) showAccountSnack(context, 'Profile updated');
    } on Object catch (error) {
      if (context.mounted) {
        showAccountSnack(context, error.toString(), error: true);
      }
    }
  }
}

class _AccountSkeleton extends StatelessWidget {
  const _AccountSkeleton();

  @override
  Widget build(BuildContext context) {
    final Color fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(height: 56, color: fill),
        const SizedBox(height: AppSpacing.md),
        Container(height: 160, color: fill),
      ],
    );
  }
}
