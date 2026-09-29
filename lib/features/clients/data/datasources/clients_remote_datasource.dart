import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/client_conversation.dart';
import '../../domain/models/client_interest.dart';
import '../../domain/models/criteria_history.dart';
import '../../domain/models/managed_client.dart';

final class ClientsRemoteDataSource {
  ClientsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ManagedClient>> listManaged() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/clients');
    return ApiEnvelope.dataList(response.data)
        .map(ManagedClient.fromJson)
        .toList();
  }

  Future<List<ClientInterest>> listInterests() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/interests');
    return ApiEnvelope.dataList(response.data)
        .map(ClientInterest.fromJson)
        .toList();
  }

  Future<List<ClientConversation>> listConversations() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/conversations');
    return ApiEnvelope.dataList(response.data)
        .map(ClientConversation.fromJson)
        .toList();
  }

  Future<ManagedClient> create({
    required String email,
    String? name,
    String? phone,
    bool sendInvitation = true,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/agent/clients',
      data: <String, dynamic>{
        'email': email,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'sendInvitation': sendInvitation,
      },
    );
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) throw const UnknownException('Client was not created');
    return ManagedClient.fromJson(data);
  }

  Future<void> delete(String id) async {
    final Response<dynamic> response =
        await _dio.delete<dynamic>('/v1/agent/clients/$id');
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
  }

  Future<void> resendInvite(String id) async {
    final Response<dynamic> response =
        await _dio.post<dynamic>('/v1/agent/clients/$id/invite', data: <String, dynamic>{});
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
  }

  Future<void> accept(String id) async {
    final Response<dynamic> response =
        await _dio.post<dynamic>('/v1/agent/clients/$id/accept', data: <String, dynamic>{});
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
  }

  Future<void> decline(String id) async {
    final Response<dynamic> response =
        await _dio.post<dynamic>('/v1/agent/clients/$id/decline', data: <String, dynamic>{});
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
  }

  Future<ClientConversation?> conversation(String id) async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/conversations/$id');
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    if (body['status'] != true) return null;
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) return null;
    return ClientConversation.fromJson(data);
  }

  Future<List<CriteriaHistoryEntry>> criteriaHistory(String buyerId) async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/criteria-history/$buyerId');
    return ApiEnvelope.dataList(response.data)
        .map(CriteriaHistoryEntry.fromJson)
        .toList();
  }
}
