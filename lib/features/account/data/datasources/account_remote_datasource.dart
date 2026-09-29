import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/agent_profile.dart';

final class AccountRemoteDataSource {
  AccountRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AgentProfile> getProfile() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/v1/profile');
      return _requireProfile(response.data, fallback: 'Profile was not found');
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<AgentProfile> updateProfile(Map<String, dynamic> body) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/v1/profile',
        data: body,
      );
      return _requireProfile(response.data, fallback: 'Profile was not updated');
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<({String? url, AgentProfile? profile})> uploadPhoto(String path) {
    return _upload(url: '/v1/profile/photo', field: 'photo', path: path);
  }

  Future<({String? url, AgentProfile? profile})> uploadVideo(String path) {
    return _upload(url: '/v1/profile/video', field: 'video', path: path);
  }

  Future<({String? url, AgentProfile? profile})> uploadLogo(String path) {
    return _upload(
      url: '/v1/profile/brokerage-logo',
      field: 'logo',
      path: path,
    );
  }

  Future<void> deleteAccount() async {
    try {
      final Response<dynamic> response = await _dio.delete<dynamic>('/v1/profile');
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<({String? url, AgentProfile? profile})> _upload({
    required String url,
    required String field,
    required String path,
  }) async {
    try {
      final FormData form = FormData.fromMap(<String, dynamic>{
        field: await MultipartFile.fromFile(path, filename: _basename(path)),
      });
      final Response<dynamic> response = await _dio.post<dynamic>(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _uploadResult(response.data);
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  AgentProfile _requireProfile(dynamic raw, {required String fallback}) {
    final Map<String, dynamic> body = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) throw UnknownException(fallback);
    return AgentProfile.fromJson(data);
  }

  ({String? url, AgentProfile? profile}) _uploadResult(dynamic raw) {
    final Map<String, dynamic> body = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) {
      throw const UnknownException('Upload failed');
    }
    final dynamic profileJson = data['profile'];
    return (
      url: data['url'] as String?,
      profile: profileJson is Map<String, dynamic>
          ? AgentProfile.fromJson(profileJson)
          : null,
    );
  }

  static String _basename(String path) {
    final int slash = path.replaceAll('\\', '/').lastIndexOf('/');
    return slash < 0 ? path : path.substring(slash + 1);
  }
}
