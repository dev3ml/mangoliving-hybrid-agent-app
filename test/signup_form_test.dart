import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangoliving_agent/core/router/app_routes.dart';
import 'package:mangoliving_agent/features/auth/domain/models/agent_user.dart';
import 'package:mangoliving_agent/features/auth/domain/signup_form.dart';
import 'package:mangoliving_agent/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mangoliving_agent/features/auth/presentation/pages/login_page.dart';
import 'package:mangoliving_agent/features/auth/presentation/pages/signup_page.dart';

class _IdleAuth extends AuthController {
  @override
  Future<AgentSession?> build() async => null;
}

void main() {
  test('signup accepts the same agent fields as the website', () {
    expect(SignupForm.validateName('Ada Lovelace'), isNull);
    expect(SignupForm.validateName(''), 'Enter your full name');
    expect(SignupForm.sanitizeName('Ada  L0velace'), 'Ada Lvelace');
    expect(
      SignupForm.splitName('Ada Lovelace'),
      (firstName: 'Ada', lastName: 'Lovelace'),
    );

    expect(SignupForm.validateEmail('ada@example.com'), isNull);
    expect(SignupForm.validateEmail('ada'), 'Enter a valid email');
    expect(SignupForm.validateMobile('5550000000'), isNull);
    expect(SignupForm.digitsOnly('(555) 000-0000'), '5550000000');

    expect(SignupForm.validatePassword('short'), isNotNull);
    expect(SignupForm.validatePassword('Password1!'), isNull);
    expect(SignupForm.validateConfirmPassword('Password1!', 'nope'), isNotNull);
    expect(SignupForm.validateLicense('CA-123456'), isNull);
    expect(SignupForm.validateLicense('12'), isNotNull);
  });

  testWidgets('sign up stays inside the app', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.login,
          builder: (BuildContext context, GoRouterState state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (BuildContext context, GoRouterState state) => const SignupPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authControllerProvider.overrideWith(_IdleAuth.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign up'), findsOneWidget);
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Create account'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Real Estate Agent ID'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
