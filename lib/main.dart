import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/env_config.dart';
import 'core/push/push_background_handler.dart';
import 'core/push/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'features/account/presentation/controllers/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(pushFirebaseBackgroundHandler);
    appLogger.info('Firebase ready (mangoliving-36fe8 — FCM)');
  } on Object catch (error, stackTrace) {
    appLogger.warning(
      'Firebase.initializeApp failed — add the agent app to project mangoliving-36fe8',
      error,
      stackTrace,
    );
  }

  appLogger.info('${AppConstants.appName} starting… API=${EnvConfig.apiBaseUrl}');

  runApp(const ProviderScope(child: MangoLivingAgentApp()));
}

class MangoLivingAgentApp extends ConsumerWidget {
  const MangoLivingAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    ref.watch(pushNotificationBootstrapProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeControllerProvider),
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        return _PushActivityHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Records a push activity heartbeat when the agent returns to the app.
class _PushActivityHost extends ConsumerStatefulWidget {
  const _PushActivityHost({required this.child});

  final Widget child;

  @override
  ConsumerState<_PushActivityHost> createState() => _PushActivityHostState();
}

class _PushActivityHostState extends ConsumerState<_PushActivityHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(ref.read(pushNotificationServiceProvider).recordActivity());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
