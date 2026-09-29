import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../messages/domain/models/chat_thread.dart';
import '../../domain/models/overview_snapshot.dart';
import 'overview_section_card.dart';

class OverviewConversations extends StatelessWidget {
  const OverviewConversations({
    super.key,
    required this.snapshot,
    required this.loading,
  });

  final OverviewSnapshot? snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OverviewSectionCard(
      title: 'Recent conversations',
      icon: Icons.chat_bubble_outline,
      trailing: TextButton(
        onPressed: () => StatefulNavigationShell.of(context).goBranch(2),
        child: const Text('View all'),
      ),
      child: loading
          ? const OverviewSkeletonList(count: 3)
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (snapshot == null || snapshot!.threadsFailed) {
      return Text(
        'No conversations yet. Messages from your clients will show up here.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final List<ChatThread> rows = snapshot!.recentThreads;
    if (rows.isEmpty) {
      return Column(
        children: <Widget>[
          Icon(
            Icons.chat_bubble_outline,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No conversations yet. Messages from your clients will show up here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      children: rows.map((ChatThread thread) {
        final String unread = TimeFormat.unreadLabel(thread.unreadCount);
        return InkWell(
          onTap: () => context.go(AppRoutes.messageThread(thread.agentClientId)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundImage: thread.avatarUrl != null &&
                          thread.avatarUrl!.isNotEmpty
                      ? NetworkImage(thread.avatarUrl!)
                      : null,
                  child: thread.avatarUrl == null || thread.avatarUrl!.isEmpty
                      ? Text(
                          thread.buyerName.isEmpty
                              ? 'C'
                              : thread.buyerName[0].toUpperCase(),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              thread.buyerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            TimeFormat.relative(thread.sortAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        thread.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
          ),
        );
      }).toList(),
    );
  }
}
