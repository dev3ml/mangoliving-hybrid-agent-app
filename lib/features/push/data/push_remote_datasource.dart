import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_logger.dart';

final pushRemoteDataSourceProvider = Provider<PushRemoteDataSource>((Ref ref) {
  return PushRemoteDataSource(ref.watch(dioProvider));
});

final class PushRemoteDataSource {
  PushRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '/v1/push/devices',
        data: <String, dynamic>{
          'token': token,
          'platform': platform,
        },
      );
      final Map<String, dynamic> envelope =
          ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(envelope);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<void> unregisterDevice({required String token}) async {
    try {
      final Response<dynamic> response = await _dio.delete<dynamic>(
        '/v1/push/devices',
        data: <String, dynamic>{'token': token},
      );
      final Map<String, dynamic> envelope =
          ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(envelope);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<void> sendDebugLog({
    required String step,
    String? detail,
    Map<String, Object?> extra = const <String, Object?>{},
  }) async {
    try {
      await _dio.post<dynamic>(
        '/v1/push/debug-log',
        data: <String, dynamic>{
          'step': step,
          'detail': detail,
          'extra': extra,
        },
      );
    } on Object catch (error) {
      appLogger.warning('push debug-log failed: $error');
    }
  }

  /// Heartbeat so the backend can target inactive users.
  Future<void> recordActivity() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/push/activity',
        data: <String, dynamic>{},
      );
      final Map<String, dynamic> envelope =
          ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(envelope);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }
}
