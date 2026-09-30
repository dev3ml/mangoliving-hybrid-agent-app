import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/agent_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/messages/presentation/controllers/chat_threads_controller.dart';
import '../../features/overview/presentation/controllers/overview_controller.dart';
import '../../features/push/data/push_remote_datasource.dart';
import '../../features/showings/presentation/controllers/showings_controller.dart';
import '../router/app_router.dart';
import '../utils/app_logger.dart';
import 'agent_push_target.dart';

const String _buyerChatChannelId = 'buyer_chat';
const String _buyerChatChannelName = 'Client messages';
const String _alertsChannelId = 'agent_alerts';
const String _alertsChannelName = 'Client activity';
const String _campaignChannelId = 'campaign';
const String _campaignChannelName = 'Updates from MangoLiving';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((Ref ref) {
  return PushNotificationService(ref);
});

/// Signed-in agents only. Buyers use the separate mobile app.
final isAuthenticatedForPushProvider = Provider<bool>((Ref ref) {
  return ref.watch(authControllerProvider).maybeWhen(
        data: (AgentSession? session) => session != null,
        orElse: () => false,
      );
});

/// FCM registration, foreground banners, tap navigation, and activity heartbeat.
final class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _initializing = false;
  String? _currentToken;
  Map<String, dynamic>? _pendingNavigation;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      while (_initializing && !_initialized) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    _initializing = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'Firebase.initializeApp failed — push stays off until '
        'google-services.json (Android, package com.mangoliving.mangoliving_agent) '
        'and GoogleService-Info.plist (iOS, bundle com.mangoliving.agent) '
        'from project mangoliving-36fe8 are added',
        error,
        stackTrace,
      );
      _initializing = false;
      return;
    }

    try {
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _buyerChatChannelId,
            _buyerChatChannelName,
            description: 'Messages from your clients',
            importance: Importance.high,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _alertsChannelId,
            _alertsChannelName,
            description: 'Showing requests and client activity',
            importance: Importance.high,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _campaignChannelId,
            _campaignChannelName,
            description: 'Property and account updates',
            importance: Importance.high,
          ),
        );
      }

      _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _openedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedMessage);

      unawaited(
        FirebaseMessaging.instance.getInitialMessage().then(
          (RemoteMessage? initial) {
            if (initial != null) _handleNavigation(initial.data);
          },
        ).catchError((Object error) {
          appLogger.warning('getInitialMessage failed: $error');
        }),
      );

      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

      _initialized = true;
    } on Object catch (error, stackTrace) {
      appLogger.warning('Push notification setup failed', error, stackTrace);
    } finally {
      _initializing = false;
    }
  }

  Future<void> registerIfNeeded() async {
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return;
      if (!_ref.read(isAuthenticatedForPushProvider)) return;

      final NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 40; i++) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }
    } on Object catch (error, stackTrace) {
      appLogger.warning('Failed to get FCM token', error, stackTrace);
    }
  }

  /// Opens a notification that arrived before the session was restored.
  void flushPendingNavigation() {
    final Map<String, dynamic>? pending = _pendingNavigation;
    if (pending == null) return;
    if (!_ref.read(isAuthenticatedForPushProvider)) return;
    _pendingNavigation = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate(AgentPushTarget.fromData(pending));
    });
  }

  Future<void> recordActivity() async {
    if (!_ref.read(isAuthenticatedForPushProvider)) return;
    try {
      await _ref.read(pushRemoteDataSourceProvider).recordActivity();
    } on Object catch (error, stackTrace) {
      appLogger.warning('Failed to record push activity', error, stackTrace);
    }
  }

  Future<void> unregister() async {
    final String? token = _currentToken;
    _currentToken = null;
    _pendingNavigation = null;
    if (token == null || token.isEmpty) return;
    try {
      await _ref.read(pushRemoteDataSourceProvider).unregisterDevice(
            token: token,
          );
    } on Object catch (error, stackTrace) {
      appLogger.warning('Failed to unregister push token', error, stackTrace);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
  }

  Future<void> _registerToken(String token) async {
    if (token.isEmpty) return;
    if (!_ref.read(isAuthenticatedForPushProvider)) return;
    _currentToken = token;
    final String platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _ref.read(pushRemoteDataSourceProvider).registerDevice(
            token: token,
            platform: platform,
          );
      unawaited(recordActivity());
      await _ref.read(pushRemoteDataSourceProvider).sendDebugLog(
        step: 'register_device_ok',
        extra: <String, Object?>{'platform': platform},
      );
    } on Object catch (error, stackTrace) {
      appLogger.warning('Failed to register FCM token', error, stackTrace);
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    final String type = data['type']?.toString() ?? '';
    _refreshFor(type);

    if (type == 'buyer_chat' || type == 'agent_chat') {
      _showChatForeground(message, data);
      return;
    }
    if (type == 'showing_request') {
      _showAlertForeground(message, data, channelId: _alertsChannelId);
      return;
    }
    if (type == 'campaign') {
      _showAlertForeground(message, data, channelId: _campaignChannelId);
    }
  }

  void _refreshFor(String type) {
    if (!_ref.read(isAuthenticatedForPushProvider)) return;
    unawaited(_ref.read(overviewControllerProvider.notifier).refresh());
    if (type == 'buyer_chat' || type == 'agent_chat') {
      unawaited(_ref.read(chatThreadsControllerProvider.notifier).refresh());
    }
    if (type == 'showing_request') {
      unawaited(_ref.read(showingsControllerProvider.notifier).refresh());
    }
  }

  void _showChatForeground(
    RemoteMessage message,
    Map<String, dynamic> data,
  ) {
    final String? agentClientId = data['agentClientId']?.toString();
    final String? activeId = _ref.read(activeChatThreadIdProvider);
    if (agentClientId != null &&
        agentClientId.isNotEmpty &&
        activeId == agentClientId) {
      return;
    }

    final RemoteNotification? notification = message.notification;
    final String title = notification?.title ??
        data['title']?.toString() ??
        'New message';
    final String body = notification?.body ?? data['body']?.toString() ?? '';
    unawaited(
      _show(
        id: agentClientId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        channelId: _buyerChatChannelId,
        channelName: _buyerChatChannelName,
        channelDescription: 'Messages from your clients',
        payload: jsonEncode(<String, String>{
          'type': 'buyer_chat',
          if (agentClientId != null && agentClientId.isNotEmpty)
            'agentClientId': agentClientId,
        }),
      ),
    );
  }

  void _showAlertForeground(
    RemoteMessage message,
    Map<String, dynamic> data, {
    required String channelId,
  }) {
    final bool campaign = channelId == _campaignChannelId;
    final RemoteNotification? notification = message.notification;
    final String title = notification?.title ??
        data['title']?.toString() ??
        'MangoLiving';
    final String body = notification?.body ?? data['body']?.toString() ?? '';
    final Map<String, String> payload = <String, String>{
      'type': campaign ? 'campaign' : (data['type']?.toString() ?? 'showing_request'),
      if (data['screen'] != null) 'screen': data['screen'].toString(),
      if (data['link'] != null) 'link': data['link'].toString(),
      if (data['agentClientId'] != null)
        'agentClientId': data['agentClientId'].toString(),
    };
    unawaited(
      _show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000000),
        title: title,
        body: body,
        channelId: channelId,
        channelName: campaign ? _campaignChannelName : _alertsChannelName,
        channelDescription: campaign
            ? 'Property and account updates'
            : 'Showing requests and client activity',
        payload: jsonEncode(payload),
      ),
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String payload,
  }) {
    return _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _onOpenedMessage(RemoteMessage message) {
    _handleNavigation(Map<String, dynamic>.from(message.data));
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final AgentPushTarget target = AgentPushTarget.fromPayload(payload);
    if (target.location == null) return;
    if (!_ref.read(isAuthenticatedForPushProvider)) {
      _pendingNavigation = _pendingFromPayload(payload);
      return;
    }
    _navigate(target);
  }

  Map<String, dynamic> _pendingFromPayload(String payload) {
    if (!payload.trim().startsWith('{')) {
      return <String, dynamic>{
        'type': 'buyer_chat',
        'agentClientId': payload.trim(),
      };
    }
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object {
      // Fall through to a chat open with the raw payload.
    }
    return <String, dynamic>{
      'type': 'buyer_chat',
      'agentClientId': payload.trim(),
    };
  }

  void _handleNavigation(Map<String, dynamic> data) {
    if (!_ref.read(isAuthenticatedForPushProvider)) {
      _pendingNavigation = data;
      return;
    }
    _navigate(AgentPushTarget.fromData(data));
  }

  void _navigate(AgentPushTarget target) {
    final String? location = target.location;
    if (location == null || location.isEmpty) return;
    final GoRouter router = _ref.read(goRouterProvider);
    if (target.replace) {
      router.go(location);
      return;
    }
    router.push(location);
  }
}

/// Wires push registration to the agent session.
final pushNotificationBootstrapProvider = Provider<void>((Ref ref) {
  final PushNotificationService service =
      ref.read(pushNotificationServiceProvider);
  var disposed = false;
  ref.listen<bool>(
    isAuthenticatedForPushProvider,
    (bool? prev, bool next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (disposed) return;
          unawaited(service.registerIfNeeded());
          service.flushPendingNavigation();
        });
      } else if (prev == true) {
        unawaited(service.unregister());
      }
    },
    fireImmediately: true,
  );
  ref.onDispose(() {
    disposed = true;
    unawaited(service.dispose());
  });
});
