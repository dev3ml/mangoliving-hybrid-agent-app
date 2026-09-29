import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';

final class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ChatThread>> listThreads() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/agent/chat/threads');
    return ApiEnvelope.dataList(response.data).map(ChatThread.fromJson).toList();
  }

  Future<List<ChatMessage>> listMessages(String agentClientId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/agent/chat/threads/${Uri.encodeComponent(agentClientId)}/messages',
    );
    return ApiEnvelope.dataList(response.data)
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> sendMessage(String agentClientId, String text) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/agent/chat/threads/${Uri.encodeComponent(agentClientId)}/messages',
      data: <String, dynamic>{'text': text},
    );
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) throw const UnknownException('Message was not sent');
    return ChatMessage.fromJson(data);
  }

  Future<void> markRead(String agentClientId) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/agent/chat/threads/${Uri.encodeComponent(agentClientId)}/read',
      data: <String, dynamic>{},
    );
    final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(body);
  }
}
