import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../controllers/chat_messages_controller.dart';
import '../controllers/chat_threads_controller.dart';

class ChatThreadPage extends ConsumerStatefulWidget {
  const ChatThreadPage({super.key, required this.agentClientId});

  final String agentClientId;

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final TextEditingController _draft = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeChatThreadIdProvider.notifier).state =
          widget.agentClientId;
      ref
          .read(chatThreadsControllerProvider.notifier)
          .markRead(widget.agentClientId);
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final String text = _draft.text;
    if (text.trim().isEmpty) return;
    try {
      await ref
          .read(chatMessagesControllerProvider(widget.agentClientId).notifier)
          .send(text);
      _draft.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ChatThread? thread;
    final List<ChatThread> threads =
        ref.watch(chatThreadsControllerProvider).valueOrNull?.threads ??
            const <ChatThread>[];
    for (final ChatThread item in threads) {
      if (item.agentClientId == widget.agentClientId) {
        thread = item;
        break;
      }
    }
    final AsyncValue<ChatMessagesState> async =
        ref.watch(chatMessagesControllerProvider(widget.agentClientId));
    final ChatMessagesState? data = async.valueOrNull;
    final bool sending = data?.sending ?? false;

    ref.listen<AsyncValue<ChatMessagesState>>(
      chatMessagesControllerProvider(widget.agentClientId),
      (AsyncValue<ChatMessagesState>? previous, AsyncValue<ChatMessagesState> next) {
        final int prevLen = previous?.valueOrNull?.messages.length ?? 0;
        final int nextLen = next.valueOrNull?.messages.length ?? 0;
        if (nextLen > prevLen) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
        }
      },
    );

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop &&
            ref.read(activeChatThreadIdProvider) == widget.agentClientId) {
          ref.read(activeChatThreadIdProvider.notifier).state = null;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          actions: DashboardAppBarActions.of(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(thread?.buyerName ?? 'Client'),
              if ((thread?.buyerEmail ?? '').isNotEmpty)
                Text(
                  thread!.buyerEmail,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(child: _transcript(async)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _draft,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        enabled: !sending,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: sending ? null : _send,
                      icon: sending
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
      ),
    );
  }

  Widget _transcript(AsyncValue<ChatMessagesState> async) {
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: Text('Loading…')),
      error: (Object error, _) => Center(child: Text(error.toString())),
      data: (ChatMessagesState data) {
        if (data.messages.isEmpty) {
          return const Center(
            child: Text('Say hello — this is the start of your conversation.'),
          );
        }
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: data.messages.length,
          itemBuilder: (BuildContext context, int index) {
            return _Bubble(message: data.messages[index]);
          },
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(mine ? AppRadius.lg : 4),
            bottomRight: Radius.circular(mine ? 4 : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              message.displayText,
              style: TextStyle(
                color: mine ? AppColors.onPrimary : theme.colorScheme.onSurface,
                fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  TimeFormat.messageTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine
                        ? AppColors.onPrimary.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (mine) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    message.isReadByBuyer ? Icons.done_all : Icons.done,
                    size: 14,
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
