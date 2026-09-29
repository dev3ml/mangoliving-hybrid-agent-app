import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/agent_user.dart';
import '../../features/overview/presentation/widgets/overview_notifications_sheet.dart';
import '../router/app_routes.dart';
import '../utils/time_format.dart';
import 'theme_toggle_button.dart';

/// Signed-in header user, kept in sync from auth + overview profile.
final dashboardUserProvider = StateProvider<AgentUser?>((Ref ref) => null);

/// Unread notification badge, kept in sync from the overview snapshot.
final dashboardUnreadProvider = StateProvider<int>((Ref ref) => 0);

/// Theme, notifications, and profile — same order as the agent web header.
abstract final class DashboardAppBarActions {
  static List<Widget> of({List<Widget> extra = const <Widget>[]}) {
    return <Widget>[
      ...extra,
      const ThemeToggleButton(),
      const NotificationBellButton(),
      const ProfileAvatarButton(),
    ];
  }
}

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(dashboardUnreadProvider);
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => showOverviewNotifications(context),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(TimeFormat.unreadLabel(unread)),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AgentUser? user = ref.watch(dashboardUserProvider);
    final String? photo = user?.photoUrl;
    final bool hasPhoto = photo != null && photo.isNotEmpty;

    return IconButton(
      tooltip: 'Account',
      onPressed: () {
        if (GoRouter.maybeOf(context) == null) return;
        if (GoRouterState.of(context).uri.path == AppRoutes.account) return;
        context.push(AppRoutes.account);
      },
      icon: CircleAvatar(
        radius: 14,
        backgroundImage: hasPhoto ? NetworkImage(photo) : null,
        child: hasPhoto
            ? null
            : Text(
                user?.initials ?? 'A',
                style: const TextStyle(fontSize: 11),
              ),
      ),
    );
  }
}

void syncDashboardUser(Ref ref, AgentUser? user) {
  ref.read(dashboardUserProvider.notifier).state = user;
}

void syncDashboardUnread(Ref ref, int unread) {
  ref.read(dashboardUnreadProvider.notifier).state = unread;
}
