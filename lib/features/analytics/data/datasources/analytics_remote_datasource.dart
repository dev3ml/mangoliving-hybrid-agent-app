import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/analytics_models.dart';

final class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AnalyticsClient>> listClients() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/analytics/clients');
    return ApiEnvelope.dataList(response.data)
        .map(AnalyticsClient.fromJson)
        .toList();
  }

  Future<AnalyticsOverview> overview({
    required String buyerId,
    required int months,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/agent/analytics/$buyerId/overview',
      queryParameters: <String, dynamic>{'months': months},
    );
    return _require(
      response.data,
      fallback: 'Analytics overview was not found',
      parse: AnalyticsOverview.fromJson,
    );
  }

  Future<AiSummary> aiSummary({
    required String buyerId,
    required int months,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/agent/analytics/$buyerId/ai-summary',
      queryParameters: <String, dynamic>{'months': months},
    );
    return _require(
      response.data,
      fallback: 'AI summary was not found',
      parse: AiSummary.fromJson,
    );
  }

  T _require<T>(
    dynamic raw, {
    required String fallback,
    required T Function(Map<String, dynamic> json) parse,
  }) {
    final Map<String, dynamic> body = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) throw UnknownException(fallback);
    return parse(data);
  }
}
