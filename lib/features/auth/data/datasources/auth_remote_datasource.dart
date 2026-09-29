import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/agent_user.dart';

/// Agent login uses the admin/agent panel endpoint, not buyer `/v1/auth/login`.
final class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AgentSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/auth/admin/login',
        data: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      );
      return _sessionFromResponse(response.data);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<AgentUser?> verifyToken(String token) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/v1/auth/verifyToken',
        options: Options(
          headers: <String, dynamic>{'Authorization': 'Bearer $token'},
        ),
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      if (body['status'] != true) return null;
      final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
      return _userFromData(data);
    } on DioException {
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/auth/forgot-password',
        data: <String, dynamic>{'email': email.trim()},
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/auth/change-password',
        data: <String, dynamic>{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  AgentSession _sessionFromResponse(dynamic raw) {
    final Map<String, dynamic> body = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic> data =
        ApiEnvelope.dataMap(body) ?? <String, dynamic>{};
    final String? token = data['token'] as String?;
    final AgentUser? user = _userFromData(data);
    if (token == null || token.isEmpty || user == null) {
      throw const UnknownException('Login failed');
    }
    if (!user.canAccessAgentPanel) {
      throw const UnknownException(
        'This account is not an agent. Use the buyer app instead.',
      );
    }
    return AgentSession(token: token, user: user);
  }

  AgentUser? _userFromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    final dynamic userJson = data['user'] ?? data;
    if (userJson is Map<String, dynamic>) {
      return AgentUser.fromJson(userJson);
    }
    return null;
  }
}
