import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../auth/domain/models/agent_user.dart';
import '../../../clients/domain/models/managed_client.dart';
import '../../../messages/domain/models/chat_thread.dart';
import '../../domain/models/agent_notification.dart';

final class OverviewRemoteDataSource {
  OverviewRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ManagedClient>> listClients() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/clients');
    return ApiEnvelope.dataList(response.data)
        .map(ManagedClient.fromJson)
        .toList();
  }

  Future<int> interestCount() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/interests');
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    final Object? total = data?['total'];
    if (total is num) return total.toInt();
    return ApiEnvelope.dataList(response.data).length;
  }

  Future<List<ChatThread>> listThreads() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/chat/threads');
    return ApiEnvelope.dataList(response.data)
        .map(ChatThread.fromJson)
        .toList();
  }

  Future<({List<AgentNotification> list, String? newestAt})>
      listNotifications() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/agent/notifications',
      queryParameters: <String, dynamic>{'limit': 50},
    );
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
    final List<AgentNotification> list = ApiEnvelope.dataList(response.data)
        .map(AgentNotification.fromJson)
        .toList();
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    return (list: list, newestAt: data?['newestAt'] as String?);
  }

  Future<AgentUser?> getProfile() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/v1/profile');
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    if (body['status'] != true) return null;
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) return null;
    return AgentUser.fromJson(data);
  }
}
