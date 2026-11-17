import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/change_password_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/inspector/domain/models/inspector_session.dart';
import '../../features/inspector/presentation/controllers/inspector_auth_controller.dart';
import '../../features/inspector/presentation/pages/inspector_booking_page.dart';
import '../../features/inspector/presentation/pages/inspector_chat_page.dart';
import '../../features/inspector/presentation/pages/inspector_flow_page.dart';
import '../../features/inspector/presentation/pages/inspector_inbox_page.dart';
import '../../features/inspector/presentation/pages/inspector_login_page.dart';
import '../../features/role/domain/app_role.dart';
import '../../features/role/presentation/app_role_controller.dart';
import '../../features/role/presentation/pages/role_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/messages/presentation/pages/chat_thread_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/more/presentation/pages/more_page.dart';
import '../../features/offers/presentation/pages/offer_summary_page.dart';
import '../../features/offers/presentation/pages/offers_page.dart';
import '../../features/offers/presentation/pages/prepare_offer_page.dart';
import '../../features/overview/presentation/pages/overview_page.dart';
import '../../features/property_search/presentation/pages/property_search_page.dart';
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
      final inspectorAuth = ref.read(inspectorAuthControllerProvider);
      final AppRole role = ref.read(appRoleProvider);
      final bool loading = auth.isLoading;
      final bool signedIn = auth.valueOrNull != null;
      final String loc = state.matchedLocation;
      final bool onSplash = loc == AppRoutes.splash;
      final bool onRole = loc == AppRoutes.role;
      final bool onInspectorOnboard = loc == AppRoutes.inspector;
      final bool onInspectorLogin = loc == AppRoutes.inspectorLogin;
      final bool onInspectorHome = loc == AppRoutes.inspectorHome;
      final bool onInspectorBooking = loc == AppRoutes.inspectorBooking;
      final bool onInspectorChat = loc.startsWith('${AppRoutes.inspectorChat}/');
      final bool onInspector = onInspectorOnboard ||
          onInspectorLogin ||
          onInspectorHome ||
          loc.startsWith('${AppRoutes.inspector}/');
      final bool onLogin = loc == AppRoutes.login;
      final bool onSignup = loc == AppRoutes.signup;
      final bool onVerify = loc == AppRoutes.verifyEmail;
      final bool onForgot = loc == AppRoutes.forgotPassword;
      final bool pendingVerify = ref.read(pendingEmailVerificationProvider);
      final bool authScreen = onLogin || onForgot || onSignup || onVerify;

      if (role == AppRole.inspector) {
        if (inspectorAuth.isLoading) {
          if (onSplash || onInspector) return null;
          return AppRoutes.splash;
        }
        final bool inspectorSignedIn = inspectorAuth.valueOrNull != null;
        if (inspectorSignedIn) {
          if (onInspectorHome ||
              onInspectorOnboard ||
              onInspectorBooking ||
              onInspectorChat) {
            return null;
          }
          return AppRoutes.inspectorHome;
        }
        if (onInspectorLogin || onInspectorOnboard) return null;
        return AppRoutes.inspectorLogin;
      }

      if (loading) {
        if (role == AppRole.agent && authScreen) return null;
        return onSplash ? null : AppRoutes.splash;
      }
      if (role == AppRole.none) {
        return onRole ? null : AppRoutes.role;
      }
      if (!signedIn) {
        return (onLogin || onForgot || onSignup) ? null : AppRoutes.login;
      }
      if (pendingVerify) {
        return onVerify ? null : AppRoutes.verifyEmail;
      }
      if (onSplash || onLogin || onForgot || onSignup || onVerify || onRole || onInspector) {
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
        path: AppRoutes.role,
        builder: (BuildContext context, GoRouterState state) {
          return const RolePage();
        },
      ),
      GoRoute(
        path: AppRoutes.inspectorLogin,
        builder: (BuildContext context, GoRouterState state) {
          return const InspectorLoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.inspectorHome,
        builder: (BuildContext context, GoRouterState state) {
          return const InspectorInboxPage();
        },
      ),
      GoRoute(
        path: AppRoutes.inspectorBooking,
        builder: (BuildContext context, GoRouterState state) {
          return InspectorBookingPage(
            token: state.uri.queryParameters['token'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.inspectorChat}/:threadId',
        builder: (BuildContext context, GoRouterState state) {
          final String id = Uri.decodeComponent(
            state.pathParameters['threadId'] ?? '',
          );
          final Object? extra = state.extra;
          return InspectorChatPage(
            threadId: id,
            title: extra is String ? extra : 'Inspection',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.inspector,
        builder: (BuildContext context, GoRouterState state) {
          return const InspectorFlowPage();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (BuildContext context, GoRouterState state) {
          return const SignupPage();
        },
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (BuildContext context, GoRouterState state) {
          return const VerifyEmailPage();
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
        path: AppRoutes.propertySearch,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const PropertySearchPage();
        },
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
                      final Object? extra = state.extra;
                      return ChatThreadPage(
                        agentClientId: id,
                        draft: extra is String ? extra : null,
                      );
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

/// Rebuilds [GoRouter] redirects when the auth session or workspace changes.
final class RouterRefresh extends ChangeNotifier {
  RouterRefresh(Ref ref) {
    _authSub = ref.listen(authControllerProvider, (_, _) => notifyListeners());
    _roleSub = ref.listen(appRoleProvider, (_, _) => notifyListeners());
    _verifySub = ref.listen(
      pendingEmailVerificationProvider,
      (_, _) => notifyListeners(),
    );
    _inspectorSub = ref.listen(
      inspectorAuthControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<dynamic>> _authSub;
  late final ProviderSubscription<AppRole> _roleSub;
  late final ProviderSubscription<bool> _verifySub;
  late final ProviderSubscription<AsyncValue<InspectorSession?>> _inspectorSub;

  @override
  void dispose() {
    _authSub.close();
    _roleSub.close();
    _verifySub.close();
    _inspectorSub.close();
    super.dispose();
  }
}
