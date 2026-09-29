import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants/env_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';

typedef ChatSocketPayload = Map<String, dynamic>;

/// Dart `socket_io_client` treats a failed WS upgrade as connect-error
/// instead of staying on polling (JS does). Prod often accepts polling only.
bool isChatSocketUpgradeFailure(Object? error) {
  final String text = error?.toString().toLowerCase() ?? '';
  if (text.isEmpty) return false;
  return text.contains('was not upgraded') ||
      (text.contains('upgrade') && text.contains('websocket'));
}

final chatSocketServiceProvider = Provider<ChatSocketService>((Ref ref) {
  final ChatSocketService service =
      ChatSocketService(ref.watch(secureStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Agent chat realtime — same events as web `agent/src/hooks/useChat.ts`.
final class ChatSocketService {
  ChatSocketService(this._storage);

  final SecureStorageService _storage;
  io.Socket? _socket;
  String? _token;
  bool _pollingOnly = false;
  bool _fallingBackToPolling = false;

  final StreamController<ChatSocketPayload> _messageController =
      StreamController<ChatSocketPayload>.broadcast();
  final StreamController<ChatSocketPayload> _readController =
      StreamController<ChatSocketPayload>.broadcast();

  Stream<ChatSocketPayload> get onMessage => _messageController.stream;
  Stream<ChatSocketPayload> get onRead => _readController.stream;

  Future<void> ensureConnected() async {
    final String? token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }
    if (_socket != null && _token == token) {
      if (_socket!.disconnected) _socket!.connect();
      return;
    }
    _openSocket(token, pollingOnly: _pollingOnly);
  }

  void _openSocket(String token, {required bool pollingOnly}) {
    _disposeSocket();
    _token = token;
    _pollingOnly = pollingOnly;
    _fallingBackToPolling = false;
    final List<String> transports = pollingOnly
        ? <String>['polling']
        : <String>['polling', 'websocket'];
    _socket = io.io(
      EnvConfig.socketBaseUrl,
      io.OptionBuilder()
          .setPath('/socket.io')
          .setAuth(<String, dynamic>{'token': token})
          .setTransports(transports)
          .setUpgrade(!pollingOnly)
          .setRememberUpgrade(false)
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(15000)
          .disableAutoConnect()
          .build(),
    );
    _socket!
      ..onConnect((_) {
        _fallingBackToPolling = false;
        appLogger.debug(
          pollingOnly
              ? 'chat socket connected (polling)'
              : 'chat socket connected',
        );
      })
      ..onDisconnect((_) => appLogger.debug('chat socket disconnected'))
      ..onConnectError((dynamic err) {
        appLogger.warning('chat socket error: $err');
        if (pollingOnly ||
            _fallingBackToPolling ||
            !isChatSocketUpgradeFailure(err)) {
          return;
        }
        _fallingBackToPolling = true;
        appLogger.warning(
          'chat socket websocket upgrade failed; retrying polling only',
        );
        _openSocket(token, pollingOnly: true);
      })
      ..on('chat:message', _emitMessage)
      ..on('chat:read', _emitRead)
      ..connect();
  }

  void _emitMessage(dynamic data) {
    final ChatSocketPayload? payload = _normalize(data);
    if (payload != null) _messageController.add(payload);
  }

  void _emitRead(dynamic data) {
    final ChatSocketPayload? payload = _normalize(data);
    if (payload != null) _readController.add(payload);
  }

  ChatSocketPayload? _normalize(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  void _disposeSocket() {
    _socket?.dispose();
    _socket = null;
  }

  void disconnect() {
    _disposeSocket();
    _token = null;
    _pollingOnly = false;
    _fallingBackToPolling = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _readController.close();
  }
}
