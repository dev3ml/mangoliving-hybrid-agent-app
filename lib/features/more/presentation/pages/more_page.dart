import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: DashboardAppBarActions.of(),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Offers'),
            subtitle: const Text('Prepare and send buyer offers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.offers),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Analytics'),
            subtitle: const Text('Client search insights'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.analytics),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            subtitle: const Text('Profile, public page, sign out'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.account),
          ),
        ],
      ),
    );
  }
}
