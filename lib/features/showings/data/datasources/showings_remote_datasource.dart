import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/showing_request.dart';

final class ShowingsRemoteDataSource {
  ShowingsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ShowingRequest>> list({ShowingStatus? status}) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/agent/showing-requests',
      queryParameters: <String, dynamic>{
        // Web omits `status` for All. `status=all` is not a real value and
        // Mongo filters it as an exact match, so the inbox comes back empty.
        if (status != null) 'status': status.apiValue,
      },
    );
    return ApiEnvelope.dataList(response.data)
        .map(ShowingRequest.fromJson)
        .toList();
  }

  Future<ShowingRequest> updateStatus({
    required String id,
    required ShowingStatus status,
    String? scheduledAt,
  }) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/v1/agent/showing-requests/$id',
      data: <String, dynamic>{
        'status': status.apiValue,
        'scheduledAt': ?scheduledAt,
      },
    );
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) throw const UnknownException('Showing was not updated');
    return ShowingRequest.fromJson(data);
  }
}
