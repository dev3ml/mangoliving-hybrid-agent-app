import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment variables loaded via [flutter_dotenv].
abstract final class EnvConfig {
  static String _read(String key, String fallback) {
    try {
      return dotenv.env[key] ?? fallback;
    } on Object {
      return fallback;
    }
  }

  static String get appName => _read('APP_NAME', 'MangoLiving Providers');

  static String get appEnv => _read('APP_ENV', 'development');

  static String get apiBaseUrl {
    final String raw = _read('API_BASE_URL', 'https://mangoliving.ai/api');
    return _rewriteLocalhostForAndroidEmulator(raw);
  }

  static String _rewriteLocalhostForAndroidEmulator(String url) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return url;
    }
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host != 'localhost' && uri.host != '127.0.0.1') return url;
    return uri.replace(host: '10.0.2.2').toString();
  }

  /// Socket.IO origin — strips a trailing `/api` from [apiBaseUrl].
  ///
  /// Built by hand. [Uri.replace] on an empty path makes Dart print port 0,
  /// and the socket then dials `https://host:0`.
  static String get socketBaseUrl {
    final Uri uri = Uri.parse(apiBaseUrl);
    String path = uri.path;
    if (path.endsWith('/api')) {
      path = path.substring(0, path.length - 4);
    }
    if (path == '/') path = '';
    final bool omitPort = !uri.hasPort ||
        uri.port == 0 ||
        (uri.scheme == 'https' && uri.port == 443) ||
        (uri.scheme == 'http' && uri.port == 80);
    final String origin = omitPort
        ? '${uri.scheme}://${uri.host}'
        : '${uri.scheme}://${uri.host}:${uri.port}';
    return '$origin$path';
  }

  static Duration get apiTimeout {
    final int seconds = int.tryParse(_read('API_TIMEOUT_SECONDS', '90')) ?? 90;
    return Duration(seconds: seconds);
  }

  static String get buyerAppUrl => normalizeBuyerAppUrl(
        _read('BUYER_APP_URL', 'https://mangoliving.ai'),
      );

  static String get agentWebUrl =>
      _read('AGENT_WEB_URL', 'https://mangoliving.ai/agents');

  static bool get isDevelopment => appEnv == 'development';
}

/// `app.mangoliving.ai` does not resolve. The buyer site is `mangoliving.ai`.
String normalizeBuyerAppUrl(String configured) {
  final String trimmed = configured.trim();
  if (trimmed.isEmpty) return 'https://mangoliving.ai';
  final Uri? uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) return 'https://mangoliving.ai';
  if (uri.host == 'app.mangoliving.ai') {
    return uri.replace(host: 'mangoliving.ai').toString();
  }
  return trimmed;
}
