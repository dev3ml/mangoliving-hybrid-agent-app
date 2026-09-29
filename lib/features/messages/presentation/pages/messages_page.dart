import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/chat_thread.dart';
import '../controllers/chat_threads_controller.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ChatThreadsState> async =
        ref.watch(chatThreadsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: DashboardAppBarActions.of(),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(chatThreadsControllerProvider.notifier).refresh(),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: AppSearchField(
                controller: _search,
                hintText: 'Search clients',
                onChanged: (String value) {
                  ref
                      .read(chatThreadsControllerProvider.notifier)
                      .setSearch(value);
                },
              ),
            ),
            Expanded(child: _body(async)),
          ],
        ),
      ),
    );
  }

  Widget _body(AsyncValue<ChatThreadsState> async) {
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: Text('Loading…')),
      error: (Object error, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          const Text('Failed to load conversations'),
          const SizedBox(height: AppSpacing.sm),
          Text(error.toString()),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () =>
                ref.read(chatThreadsControllerProvider.notifier).refresh(),
            child: const Text('Try again'),
          ),
        ],
      ),
      data: (ChatThreadsState data) {
        final List<ChatThread> threads = data.visible;
        if (threads.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              const SizedBox(height: 80),
              Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  data.search.trim().isEmpty
                      ? 'No connected clients yet'
                      : 'No matches',
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: threads.length,
          separatorBuilder: (_, _) => const Divider(indent: 76),
          itemBuilder: (BuildContext context, int index) {
            return _ThreadTile(thread: threads[index]);
          },
        );
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String unread = TimeFormat.unreadLabel(thread.unreadCount);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      leading: CircleAvatar(
        backgroundImage:
            thread.avatarUrl != null && thread.avatarUrl!.isNotEmpty
                ? NetworkImage(thread.avatarUrl!)
                : null,
        child: thread.avatarUrl == null || thread.avatarUrl!.isEmpty
            ? Text(thread.initials)
            : null,
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              thread.buyerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            TimeFormat.messageTime(thread.sortAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              thread.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unread.isNotEmpty) ...<Widget>[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.destructive,
              child: Text(
                unread,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push(AppRoutes.messageThread(thread.agentClientId)),
    );
  }
}
