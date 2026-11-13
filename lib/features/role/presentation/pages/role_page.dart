import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mango_living_logo.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/app_role.dart';
import '../app_role_controller.dart';

class RolePage extends ConsumerWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const MangoLivingLogo(fontSize: 36),
                        const SizedBox(height: 28),
                        Text(
                          'How will you use MangoLiving?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose a workspace. The next time you open the app, you can choose again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 28),
                        _RoleCard(
                          icon: Icons.badge_outlined,
                          title: 'Agent',
                          detail: 'Clients, showings, offers, and messages.',
                          onTap: () => _choose(context, ref, AppRole.agent),
                        ),
                        const SizedBox(height: 12),
                        _RoleCard(
                          icon: Icons.fact_check_outlined,
                          title: 'Inspector',
                          detail:
                              'Home inspections, pricing, and your provider profile.',
                          onTap: () => _choose(context, ref, AppRole.inspector),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _choose(BuildContext context, WidgetRef ref, AppRole role) {
    ref.read(appRoleProvider.notifier).state = role;
    if (role == AppRole.inspector) {
      context.go(AppRoutes.inspectorLogin);
      return;
    }
    final bool signedIn = ref.read(authControllerProvider).valueOrNull != null;
    context.go(signedIn ? AppRoutes.overview : AppRoutes.login);
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF241C18) : Colors.white,
      elevation: dark ? 0 : 1,
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? const Color(0xFF3A302A) : const Color(0xFFF0E6DE),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dark ? AppColors.accentWashDark : AppColors.accentWash,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        color: dark ? AppColors.mutedDark : AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
