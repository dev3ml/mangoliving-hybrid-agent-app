import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((Ref ref) {
  return MessagesRepositoryImpl(
    MessagesRemoteDataSource(ref.watch(dioProvider)),
  );
});

final class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);

  final MessagesRemoteDataSource _remote;

  @override
  Future<List<ChatThread>> listThreads() async {
    final List<ChatThread> clients = await _guard(_remote.listThreads);
    try {
      final List<ChatThread> rooms = await _guard(_remote.listInspectionThreads);
      return <ChatThread>[...clients, ...rooms];
    } on Object {
      return clients;
    }
  }

  @override
  Future<List<ChatMessage>> listMessages(String agentClientId) {
    if (agentClientId.startsWith(ChatThread.inspectionPrefix)) {
      return _guard(
        () => _remote.listInspectionMessages(
          agentClientId.substring(ChatThread.inspectionPrefix.length),
        ),
      );
    }
    return _guard(() => _remote.listMessages(agentClientId));
  }

  @override
  Future<ChatMessage> sendMessage(String agentClientId, String text) {
    if (agentClientId.startsWith(ChatThread.inspectionPrefix)) {
      return _guard(
        () => _remote.sendInspectionMessage(
          agentClientId.substring(ChatThread.inspectionPrefix.length),
          text,
        ),
      );
    }
    return _guard(() => _remote.sendMessage(agentClientId, text));
  }

  @override
  Future<void> markRead(String agentClientId) {
    if (agentClientId.startsWith(ChatThread.inspectionPrefix)) {
      return _guard(
        () => _remote.markInspectionRead(
          agentClientId.substring(ChatThread.inspectionPrefix.length),
        ),
      );
    }
    return _guard(() => _remote.markRead(agentClientId));
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }
}
