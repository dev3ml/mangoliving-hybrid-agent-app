import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/change_password_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/messages/presentation/pages/chat_thread_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/more/presentation/pages/more_page.dart';
import '../../features/offers/presentation/pages/offer_summary_page.dart';
import '../../features/offers/presentation/pages/offers_page.dart';
import '../../features/offers/presentation/pages/prepare_offer_page.dart';
import '../../features/overview/presentation/pages/overview_page.dart';
import '../../features/shell/presentation/pages/main_shell.dart';
import '../../features/showings/presentation/pages/showings_page.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((Ref ref) {
  final RouterRefresh refresh = RouterRefresh(ref);

  final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final auth = ref.read(authControllerProvider);
      final bool loading = auth.isLoading;
      final bool signedIn = auth.valueOrNull != null;
      final String loc = state.matchedLocation;
      final bool onSplash = loc == AppRoutes.splash;
      final bool onLogin = loc == AppRoutes.login;
      final bool onForgot = loc == AppRoutes.forgotPassword;

      if (loading) {
        if (onLogin || onForgot) return null;
        return onSplash ? null : AppRoutes.splash;
      }
      if (!signedIn) {
        return (onLogin || onForgot) ? null : AppRoutes.login;
      }
      if (onSplash || onLogin || onForgot) {
        return AppRoutes.overview;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordPage();
        },
      ),
      GoRoute(
        path: AppRoutes.offers,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const OffersPage();
        },
        routes: <RouteBase>[
          GoRoute(
            path: ':id/prepare',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (BuildContext context, GoRouterState state) {
              final String id = Uri.decodeComponent(
                state.pathParameters['id'] ?? '',
              );
              return PrepareOfferPage(actionId: id);
            },
          ),
          GoRoute(
            path: ':id/summary',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (BuildContext context, GoRouterState state) {
              final String id = Uri.decodeComponent(
                state.pathParameters['id'] ?? '',
              );
              return OfferSummaryPage(actionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.analytics,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const AnalyticsPage();
        },
      ),
      GoRoute(
        path: AppRoutes.account,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const AccountPage();
        },
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const ChangePasswordPage();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.overview,
                builder: (BuildContext context, GoRouterState state) {
                  return const OverviewPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.clients,
                builder: (BuildContext context, GoRouterState state) {
                  return const ClientsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.messages,
                builder: (BuildContext context, GoRouterState state) {
                  return const MessagesPage();
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':agentClientId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = Uri.decodeComponent(
                        state.pathParameters['agentClientId'] ?? '',
                      );
                      return ChatThreadPage(agentClientId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.showings,
                builder: (BuildContext context, GoRouterState state) {
                  return const ShowingsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.more,
                builder: (BuildContext context, GoRouterState state) {
                  return const MorePage();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(refresh.dispose);
  return router;
});

/// Rebuilds [GoRouter] redirects when the auth session changes.
final class RouterRefresh extends ChangeNotifier {
  RouterRefresh(Ref ref) {
    _sub = ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<dynamic>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
