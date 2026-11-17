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

  Future<AgentSession> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required bool smsConsent,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/auth/signup',
        data: <String, dynamic>{
          'email': email.trim(),
          'password': password,
          'firstName': firstName.trim(),
          if (lastName.trim().isNotEmpty) 'lastName': lastName.trim(),
          'mobileNumber': mobileNumber.trim(),
          'smsConsent': smsConsent,
          'userType': 'agent',
        },
      );
      return _sessionFromResponse(response.data);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  /// The signup route does not store a license number. The account screen
  /// already saves it with this profile update.
  Future<void> saveLicenseNumber(String licenseNumber) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/v1/profile',
        data: <String, dynamic>{'licenseNumber': licenseNumber.trim()},
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<AgentUser?> verifyEmail(String code) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/auth/verify-email',
        data: <String, dynamic>{'code': code.trim()},
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
      return _userFromData(ApiEnvelope.dataMap(body));
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<({bool alreadyVerified, int? cooldownSeconds})> resendVerification() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/v1/auth/resend-verification',
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
      final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
      return (
        alreadyVerified: data?['alreadyVerified'] == true,
        cooldownSeconds: _asInt(data?['cooldownSeconds']),
      );
    } on DioException catch (error) {
      final int? retryAfter = _retryAfterSeconds(error);
      if (retryAfter != null) {
        throw VerificationCooldownException(
          retryAfter,
          _messageFromDio(error) ?? 'Please wait before requesting a new code',
        );
      }
      throw ExceptionMapper.fromDio(error);
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

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value');
  }

  int? _retryAfterSeconds(DioException error) {
    if (error.response?.statusCode != 429) return null;
    final dynamic data = error.response?.data;
    if (data is! Map) return null;
    final dynamic nested = data['data'];
    if (nested is Map && nested['retryAfterSeconds'] != null) {
      return _asInt(nested['retryAfterSeconds']);
    }
    return _asInt(data['retryAfterSeconds']);
  }

  String? _messageFromDio(DioException error) {
    final dynamic data = error.response?.data;
    if (data is Map && data['message'] is String) {
      final String message = (data['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    return null;
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
