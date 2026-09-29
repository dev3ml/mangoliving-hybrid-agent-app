import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/chat_socket_service.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/repositories/messages_repository.dart';

final activeChatThreadIdProvider = StateProvider<String?>((Ref ref) => null);

final chatThreadsControllerProvider =
    AsyncNotifierProvider<ChatThreadsController, ChatThreadsState>(
  ChatThreadsController.new,
);

final class ChatThreadsState {
  const ChatThreadsState({
    required this.threads,
    this.search = '',
  });

  final List<ChatThread> threads;
  final String search;

  int get unreadTotal =>
      threads.fold<int>(0, (int sum, ChatThread t) => sum + t.unreadCount);

  List<ChatThread> get visible {
    final String q = search.trim().toLowerCase();
    final List<ChatThread> sorted = threads.toList()
      ..sort((ChatThread a, ChatThread b) {
        final DateTime? left = DateTime.tryParse(a.sortAt);
        final DateTime? right = DateTime.tryParse(b.sortAt);
        if (left == null || right == null) return 0;
        return right.compareTo(left);
      });
    if (q.isEmpty) return sorted;
    return sorted.where((ChatThread t) {
      return t.buyerName.toLowerCase().contains(q) ||
          t.buyerEmail.toLowerCase().contains(q);
    }).toList();
  }

  ChatThreadsState copyWith({List<ChatThread>? threads, String? search}) {
    return ChatThreadsState(
      threads: threads ?? this.threads,
      search: search ?? this.search,
    );
  }
}

class ChatThreadsController extends AsyncNotifier<ChatThreadsState> {
  MessagesRepository get _repo => ref.read(messagesRepositoryProvider);
  ChatSocketService get _socket => ref.read(chatSocketServiceProvider);

  StreamSubscription<ChatSocketPayload>? _messageSub;
  StreamSubscription<ChatSocketPayload>? _readSub;

  @override
  Future<ChatThreadsState> build() async {
    ref.onDispose(() {
      _messageSub?.cancel();
      _readSub?.cancel();
    });
    if (ref.watch(authControllerProvider).valueOrNull == null) {
      _socket.disconnect();
      return const ChatThreadsState(threads: <ChatThread>[]);
    }
    try {
      await _socket.ensureConnected();
      _messageSub = _socket.onMessage.listen(_onSocketMessage);
      _readSub = _socket.onRead.listen(_onSocketRead);
    } on Object {
      // REST list still loads if the socket handshake fails.
    }
    final List<ChatThread> threads = await _repo.listThreads();
    return ChatThreadsState(threads: threads);
  }

  Future<void> refresh() async {
    final String search = state.valueOrNull?.search ?? '';
    try {
      await _socket.ensureConnected();
      final List<ChatThread> threads = await _repo.listThreads();
      state = AsyncData<ChatThreadsState>(
        ChatThreadsState(threads: threads, search: search),
      );
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<ChatThreadsState>(error, stackTrace);
      }
    }
  }

  void setSearch(String search) {
    final ChatThreadsState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<ChatThreadsState>(current.copyWith(search: search));
  }

  Future<void> markRead(String agentClientId) async {
    _setUnread(agentClientId, 0);
    try {
      await _repo.markRead(agentClientId);
    } on Object {
      // Keep local zero; next refresh corrects if the server rejected.
    }
  }

  void applySent(ChatMessage message) {
    _upsertFromMessage(message, incrementUnread: false);
  }

  void _onSocketMessage(ChatSocketPayload payload) {
    final ChatMessage message = ChatMessage.fromJson(payload);
    if (message.agentClientId.isEmpty) return;
    final String? openId = ref.read(activeChatThreadIdProvider);
    final bool increment =
        !message.isMine && openId != message.agentClientId;
    _upsertFromMessage(message, incrementUnread: increment);
    if (!increment && !message.isMine && openId == message.agentClientId) {
      unawaited(markRead(message.agentClientId));
    }
  }

  void _onSocketRead(ChatSocketPayload payload) {
    if (payload['by'] == 'agent') {
      final String? id = payload['agentClientId']?.toString();
      if (id != null && id.isNotEmpty) _setUnread(id, 0);
    }
  }

  void _upsertFromMessage(ChatMessage message, {required bool incrementUnread}) {
    final ChatThreadsState? current = state.valueOrNull;
    if (current == null) return;
    final List<ChatThread> next = current.threads.toList();
    final int index = next.indexWhere(
      (ChatThread t) => t.agentClientId == message.agentClientId,
    );
    if (index >= 0) {
      final ChatThread existing = next[index];
      next[index] = existing.copyWith(
        lastMessageText: message.displayText,
        lastMessageAt: message.createdAt,
        lastSenderRole: message.senderRole,
        updatedAt: message.createdAt,
        unreadCount: incrementUnread
            ? existing.unreadCount + 1
            : existing.unreadCount,
      );
    } else if (incrementUnread || message.isMine) {
      next.insert(
        0,
        ChatThread(
          agentClientId: message.agentClientId,
          buyerName: 'Client',
          unreadCount: incrementUnread ? 1 : 0,
          updatedAt: message.createdAt,
          lastMessageText: message.displayText,
          lastMessageAt: message.createdAt,
          lastSenderRole: message.senderRole,
        ),
      );
    }
    state = AsyncData<ChatThreadsState>(current.copyWith(threads: next));
  }

  void _setUnread(String agentClientId, int count) {
    final ChatThreadsState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<ChatThreadsState>(
      current.copyWith(
        threads: current.threads
            .map(
              (ChatThread t) => t.agentClientId == agentClientId
                  ? t.copyWith(unreadCount: count)
                  : t,
            )
            .toList(),
      ),
    );
  }
}
