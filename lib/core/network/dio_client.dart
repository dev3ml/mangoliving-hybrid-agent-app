import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/env_config.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Shared [Dio] client with JWT injection and the `{ status, message, data }` envelope.
final dioProvider = Provider<Dio>((Ref ref) {
  final SecureStorageService storage = ref.watch(secureStorageProvider);
  return DioClient.create(tokenProvider: storage.getAccessToken);
});

abstract final class DioClient {
  static Dio create({Future<String?> Function()? tokenProvider}) {
    final String platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'mobile',
    };

    final Dio dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: EnvConfig.apiTimeout,
        receiveTimeout: EnvConfig.apiTimeout,
        sendTimeout: EnvConfig.apiTimeout,
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device-Platform': platform,
        },
      ),
    );

    dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(tokenProvider: tokenProvider),
      LoggingInterceptor(appLogger),
    ]);

    return dio;
  }
}
