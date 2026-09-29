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
  Future<List<ChatThread>> listThreads() => _guard(_remote.listThreads);

  @override
  Future<List<ChatMessage>> listMessages(String agentClientId) {
    return _guard(() => _remote.listMessages(agentClientId));
  }

  @override
  Future<ChatMessage> sendMessage(String agentClientId, String text) {
    return _guard(() => _remote.sendMessage(agentClientId, text));
  }

  @override
  Future<void> markRead(String agentClientId) {
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
