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

  static String get appName => _read('APP_NAME', 'MangoLiving Agent');

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
  static String get socketBaseUrl {
    final Uri uri = Uri.parse(apiBaseUrl);
    if (uri.path.endsWith('/api')) {
      return uri
          .replace(path: uri.path.substring(0, uri.path.length - 4))
          .origin;
    }
    return uri.origin;
  }

  static Duration get apiTimeout {
    final int seconds = int.tryParse(_read('API_TIMEOUT_SECONDS', '90')) ?? 90;
    return Duration(seconds: seconds);
  }

  static String get buyerAppUrl =>
      _read('BUYER_APP_URL', 'https://app.mangoliving.ai');

  static String get agentWebUrl =>
      _read('AGENT_WEB_URL', 'https://mangoliving.ai/agents');

  static bool get isDevelopment => appEnv == 'development';
}
