import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../messages/data/chat_socket_service.dart';
import '../../../messages/domain/models/chat_message.dart';
import '../../../messages/domain/models/chat_thread.dart';
import '../../data/inspector_auth_remote.dart';

/// Group room for one paid inspection, opened by the inspector.
class InspectorChatPage extends ConsumerStatefulWidget {
  const InspectorChatPage({
    super.key,
    required this.threadId,
    required this.title,
  });

  final String threadId;
  final String title;

  @override
  ConsumerState<InspectorChatPage> createState() => _InspectorChatPageState();
}

class _InspectorChatPageState extends ConsumerState<InspectorChatPage> {
  final TextEditingController _draft = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  StreamSubscription<ChatSocketPayload>? _socketSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final InspectorAuthRemote remote = ref.read(inspectorAuthRemoteProvider);
    try {
      final ChatSocketService socket = ref.read(inspectorChatSocketProvider);
      await socket.ensureConnected();
      _socketSub ??= socket.onMessage.listen(_onSocket);
      final List<ChatMessage> messages =
          await remote.inspectionMessages(widget.threadId);
      await remote.markInspectionRead(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      _scrollToEnd();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _onSocket(ChatSocketPayload payload) {
    final ChatMessage message = ChatMessage.fromJson(payload);
    if (message.agentClientId != ChatThread.inspectionKey(widget.threadId)) {
      return;
    }
    if (_messages.any((ChatMessage item) => item.id == message.id)) return;
    setState(() => _messages = <ChatMessage>[..._messages, message]);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final String text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final ChatMessage sent = await ref
          .read(inspectorAuthRemoteProvider)
          .sendInspectionMessage(widget.threadId, text);
      if (!mounted) return;
      _draft.clear();
      setState(() {
        _sending = false;
        if (_messages.every((ChatMessage item) => item.id != sent.id)) {
          _messages = <ChatMessage>[..._messages, sent];
        }
      });
      _scrollToEnd();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Inspection', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: _transcript()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _draft,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(hintText: 'Type a message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcript() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_messages.isEmpty) {
      return const Center(
        child: Text('Say hello — this is the start of your conversation.'),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int index) {
        final ChatMessage message = _messages[index];
        final bool mine = message.isMine;
        final ColorScheme colors = Theme.of(context).colorScheme;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(
              color: mine ? AppColors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                if (!mine && message.senderName.trim().isNotEmpty)
                  Text(
                    '${message.senderName} · ${_seat(message.senderRole)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                Text(
                  message.displayText,
                  style: TextStyle(
                    color: mine ? AppColors.onPrimary : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _seat(String role) {
    return switch (role) {
      'agent' => 'Agent',
      'buyer' => 'Buyer',
      'inspector' => 'Inspector',
      _ => role,
    };
  }
}

final inspectorChatThreadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((Ref ref) async {
  return ref.watch(inspectorAuthRemoteProvider).inspectionThreads();
});
