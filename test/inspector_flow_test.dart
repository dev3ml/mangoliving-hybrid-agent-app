import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangoliving_agent/core/router/app_routes.dart';
import 'package:mangoliving_agent/features/inspector/data/inspector_local_repository.dart';
import 'package:mangoliving_agent/features/inspector/domain/models/inspector_draft.dart';
import 'package:mangoliving_agent/features/inspector/domain/models/inspector_session.dart';
import 'package:mangoliving_agent/features/inspector/presentation/controllers/inspector_auth_controller.dart';
import 'package:mangoliving_agent/features/inspector/presentation/controllers/inspector_flow_controller.dart';
import 'package:mangoliving_agent/features/inspector/presentation/pages/inspector_flow_page.dart';
import 'package:mangoliving_agent/features/inspector/presentation/pages/inspector_login_page.dart';
import 'package:mangoliving_agent/features/role/presentation/pages/role_page.dart';

class _NullInspectorAuth extends InspectorAuthController {
  @override
  Future<InspectorSession?> build() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('agent door opens the agent sign-in route', (WidgetTester tester) async {
    final GoRouter router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);

    await tester.tap(find.text('Agent'));
    await tester.pumpAndSettle();

    expect(find.text('Agent login'), findsOneWidget);
  });

  testWidgets('inspector door opens sign-in then onboarding', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final GoRouter router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inspector'));
    await tester.pumpAndSettle();

    expect(find.text('Inspector login'), findsOneWidget);
    await tester.tap(find.text('Create an inspector profile'));
    await tester.pumpAndSettle();

    expect(find.text('Join MangoLiving'), findsOneWidget);
    await _enter(tester, 'Alex Morgan', 'Alex Morgan');
    await _enter(tester, 'alex@example.com', 'alex@example.com');
    await _enter(tester, '(555) 010-2040', '5550102040');
    await _enter(tester, '••••••••', 'secret123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await _primary(tester);

    expect(find.textContaining('Account verified'), findsOneWidget);
    await _enter(tester, 'Morgan Home Inspections', 'Morgan Home Inspections');
    await _chooseOption(tester, const Key('years-of-experience'), '8 years');
    await _enter(
      tester,
      'Residential inspections with clear reports and a buyer walkthrough.',
      'Clear reports and a buyer walkthrough.',
    );
    await _primary(tester);

    expect(find.text('Show your qualifications'), findsOneWidget);
    await _enter(tester, 'Enter license number', 'TREC-100');
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorFlowPage)),
    );
    container.read(inspectorFlowControllerProvider.notifier).patch(
          (InspectorDraft current) => current.copyWith(
            licensingState: 'Texas',
            licenseFileName: 'license.pdf',
            insuranceFileName: 'insurance.pdf',
          ),
        );
    await tester.pump();
    await _primary(tester);

    expect(find.text('Where do you inspect?'), findsOneWidget);
    final Finder addArea = find.byKey(const Key('add-service-area'));
    await tester.ensureVisible(addArea);
    await tester.tap(addArea);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Frisco');
    await tester.tap(find.byKey(const Key('confirm-service-area')));
    await tester.pumpAndSettle();
    await _primary(tester);

    expect(find.text('Structure & exterior'), findsOneWidget);
    await _primary(tester);
    expect(find.text('Interior & insulation'), findsOneWidget);
    await _primary(tester);
    expect(find.text('Home systems'), findsOneWidget);
    await _primary(tester);
    expect(find.text('Appliances & equipment'), findsOneWidget);
    await _primary(tester);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(InspectorFlowPage)),
      ).read(inspectorFlowControllerProvider).requireValue.step,
      InspectorStep.pricingTypes,
    );

    for (int type = 0; type < 3; type++) {
      await _primary(tester);
      await _fillPrices(tester);
      await _primary(tester);
      await _fillPrices(tester);
      await _primary(tester);
    }

    final InspectorStep pricedStep = ProviderScope.containerOf(
      tester.element(find.byType(InspectorFlowPage)),
    ).read(inspectorFlowControllerProvider).requireValue.step;
    expect(pricedStep, InspectorStep.pricingSummary, reason: '$pricedStep');
    expect(find.text('Base pricing complete'), findsOneWidget);
    await _primary(tester);

    for (int page = 0; page < 3; page++) {
      expect(find.text('Optional add-ons'), findsOneWidget);
      await _primary(tester);
    }

    expect(find.text('Preview a quote'), findsOneWidget);
    await _enter(tester, '1998', '1998');
    await _enter(tester, '2,800', '2800');
    await tester.pumpAndSettle();
    await _primary(tester);

    expect(find.text('When can you inspect?'), findsOneWidget);
    await _primary(tester);

    expect(find.text('Ready to go live?'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await _primary(tester);

    expect(find.text('You’re approved'), findsOneWidget);
    expect(find.text('Approved'), findsWidgets);
    expect(find.text('Open requests inbox'), findsOneWidget);
  });
}

Widget _app(GoRouter router) {
  return ProviderScope(
    overrides: <Override>[
      inspectorAuthControllerProvider.overrideWith(_NullInspectorAuth.new),
      inspectorOnboardingWithAuthProvider.overrideWithValue(
        InspectorLocalRepository(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: AppRoutes.role,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.role,
        builder: (BuildContext context, GoRouterState state) => const RolePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Text('Agent login'));
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
          return const Scaffold(body: Text('Inspector inbox'));
        },
      ),
      GoRoute(
        path: AppRoutes.inspector,
        builder: (BuildContext context, GoRouterState state) {
          return const InspectorFlowPage();
        },
      ),
    ],
  );
}

Future<void> _enter(WidgetTester tester, String hint, String value) async {
  final Finder field = find.byWidgetPredicate(
    (Widget widget) =>
        widget is TextField && widget.decoration?.hintText == hint,
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _chooseOption(WidgetTester tester, Key key, String option) async {
  final Finder field = find.byKey(key);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  final Finder item = find.text(option).last;
  await tester.scrollUntilVisible(
    item,
    48,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> _primary(WidgetTester tester) async {
  final Finder button = find.byKey(const Key('inspector-primary-action'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _fillPrices(WidgetTester tester) async {
  final Finder fields = find.byType(TextField);
  for (int i = 0; i < 3; i++) {
    await tester.enterText(fields.at(i), '${400 + i * 50}');
    await tester.pump();
  }
}
