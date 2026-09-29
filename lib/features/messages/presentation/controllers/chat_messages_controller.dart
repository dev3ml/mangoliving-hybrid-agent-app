import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_socket_service.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/messages_repository.dart';
import 'chat_threads_controller.dart';

final chatMessagesControllerProvider = AsyncNotifierProvider.family<
    ChatMessagesController, ChatMessagesState, String>(
  ChatMessagesController.new,
);

final class ChatMessagesState {
  const ChatMessagesState({
    required this.messages,
    this.sending = false,
  });

  final List<ChatMessage> messages;
  final bool sending;

  ChatMessagesState copyWith({List<ChatMessage>? messages, bool? sending}) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
    );
  }
}

class ChatMessagesController
    extends FamilyAsyncNotifier<ChatMessagesState, String> {
  MessagesRepository get _repo => ref.read(messagesRepositoryProvider);
  ChatSocketService get _socket => ref.read(chatSocketServiceProvider);

  StreamSubscription<ChatSocketPayload>? _messageSub;
  StreamSubscription<ChatSocketPayload>? _readSub;

  String get _agentClientId => arg;

  @override
  Future<ChatMessagesState> build(String arg) async {
    ref.onDispose(() {
      _messageSub?.cancel();
      _readSub?.cancel();
    });
    await _socket.ensureConnected();
    _messageSub = _socket.onMessage.listen(_onSocketMessage);
    _readSub = _socket.onRead.listen(_onSocketRead);
    final List<ChatMessage> messages = await _repo.listMessages(arg);
    return ChatMessagesState(messages: messages);
  }

  Future<void> send(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final ChatMessagesState? current = state.valueOrNull;
    if (current == null || current.sending) return;
    state = AsyncData<ChatMessagesState>(current.copyWith(sending: true));
    try {
      final ChatMessage sent = await _repo.sendMessage(_agentClientId, trimmed);
      final ChatMessagesState latest =
          state.valueOrNull ?? ChatMessagesState(messages: current.messages);
      if (latest.messages.every((ChatMessage m) => m.id != sent.id)) {
        state = AsyncData<ChatMessagesState>(
          latest.copyWith(
            messages: <ChatMessage>[...latest.messages, sent],
            sending: false,
          ),
        );
      } else {
        state = AsyncData<ChatMessagesState>(latest.copyWith(sending: false));
      }
      ref.read(chatThreadsControllerProvider.notifier).applySent(sent);
    } on Object catch (error, stackTrace) {
      state = AsyncError<ChatMessagesState>(error, stackTrace);
      if (current.messages.isNotEmpty) {
        state = AsyncData<ChatMessagesState>(
          current.copyWith(sending: false),
        );
      }
      rethrow;
    }
  }

  void _onSocketMessage(ChatSocketPayload payload) {
    final ChatMessage message = ChatMessage.fromJson(payload);
    if (message.agentClientId != _agentClientId) return;
    final ChatMessagesState? current = state.valueOrNull;
    if (current == null) return;
    if (current.messages.any((ChatMessage m) => m.id == message.id)) return;
    state = AsyncData<ChatMessagesState>(
      current.copyWith(messages: <ChatMessage>[...current.messages, message]),
    );
  }

  void _onSocketRead(ChatSocketPayload payload) {
    if (payload['by'] != 'buyer') return;
    if (payload['agentClientId']?.toString() != _agentClientId) return;
    final ChatMessagesState? current = state.valueOrNull;
    if (current == null) return;
    final String now = DateTime.now().toIso8601String();
    state = AsyncData<ChatMessagesState>(
      current.copyWith(
        messages: current.messages
            .map(
              (ChatMessage m) =>
                  m.isMine && !m.isReadByBuyer ? m.copyWith(readByBuyerAt: now) : m,
            )
            .toList(),
      ),
    );
  }
}
