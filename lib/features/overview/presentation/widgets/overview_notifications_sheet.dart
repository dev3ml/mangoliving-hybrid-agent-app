import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/agent_notification.dart';
import '../../domain/models/overview_snapshot.dart';
import '../controllers/overview_controller.dart';

Future<void> showOverviewNotifications(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return const OverviewNotificationsSheet();
    },
  );
}

class OverviewNotificationsSheet extends ConsumerWidget {
  const OverviewNotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OverviewSnapshot> async =
        ref.watch(overviewControllerProvider);
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: async.when(
          loading: () => const Center(child: Text('Loading…')),
          error: (_, _) => const Center(
            child: Text('Failed to load notifications'),
          ),
          data: (OverviewSnapshot snapshot) {
            if (snapshot.notificationsFailed) {
              return const Center(child: Text('Failed to load notifications'));
            }
            if (snapshot.notifications.isEmpty) {
              return const Center(child: Text("You're all caught up."));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      Text('Notifications', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      if (snapshot.unreadNotificationCount > 0)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(overviewControllerProvider.notifier)
                                .markAllNotificationsRead();
                          },
                          child: const Text('Mark all read'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: snapshot.notifications.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final AgentNotification item =
                          snapshot.notifications[index];
                      final bool unread = item.isUnread(snapshot.lastReadAt);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 5,
                          backgroundColor:
                              unread ? AppColors.primary : AppColors.divider,
                        ),
                        title: Text(item.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (item.message != null && item.message!.isNotEmpty)
                              Text(
                                item.message!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(TimeFormat.relative(item.createdAt)),
                          ],
                        ),
                        onTap: () {
                          ref
                              .read(overviewControllerProvider.notifier)
                              .markNotificationRead(item.createdAt);
                          Navigator.of(context).pop();
                          _openLink(context, item.link);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _goTab(context, 1, AppRoutes.clients);
                    },
                    child: const Text('View all in Clients'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openLink(BuildContext context, String? link) {
    final String path = (link ?? '').toLowerCase();
    if (path.contains('showing')) {
      _goTab(context, 3, AppRoutes.showings);
      return;
    }
    if (path.contains('message')) {
      _goTab(context, 2, AppRoutes.messages);
      return;
    }
    if (path.contains('analytic')) {
      context.push(AppRoutes.analytics);
      return;
    }
    _goTab(context, 1, AppRoutes.clients);
  }

  void _goTab(BuildContext context, int branch, String route) {
    try {
      StatefulNavigationShell.of(context).goBranch(branch);
    } on Object {
      context.go(route);
    }
  }
}
