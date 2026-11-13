import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/client_conversation.dart';
import '../../../showings/domain/models/showing_request.dart';
import '../../../showings/presentation/controllers/showings_controller.dart';
import '../../domain/models/roster_client.dart';
import '../controllers/clients_controller.dart';
import 'client_search_history_sheet.dart';

Future<void> showClientDetailsSheet(BuildContext context, RosterClient client) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => ClientDetailsSheet(client: client),
    ),
  );
}

class ClientDetailsSheet extends ConsumerStatefulWidget {
  const ClientDetailsSheet({super.key, required this.client});

  final RosterClient client;

  @override
  ConsumerState<ClientDetailsSheet> createState() => _ClientDetailsSheetState();
}

class _ClientDetailsSheetState extends ConsumerState<ClientDetailsSheet> {
  Future<ClientConversation?>? _conversation;

  @override
  void initState() {
    super.initState();
    final String? id = widget.client.conversationId;
    if (id != null && id.isNotEmpty) {
      _conversation =
          ref.read(clientsControllerProvider.notifier).loadConversation(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final RosterClient client = widget.client;
    final ThemeData theme = Theme.of(context);
    final bool light = theme.brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'View client information, activity history, and recent messages',
                style: TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: light ? Colors.white : const Color(0xFF241C18),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFFFE4D0),
                        child: Text(
                          client.initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              client.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              <String>[
                                if (client.email.isNotEmpty) client.email,
                                if (client.phone.isNotEmpty) client.phone,
                              ].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _DetailPill(label: client.statusLabel),
                      if (client.buyerMode == BuyerMode.sharing)
                        const _DetailPill(
                          label: 'Sharing',
                          icon: Icons.visibility_rounded,
                          foreground: Colors.white,
                          background: AppColors.sharing,
                        ),
                      if (client.buyerMode == BuyerMode.privacy)
                        const _DetailPill(
                          label: 'Privacy',
                          icon: Icons.visibility_off_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${client.searches} searches · ${client.messages} messages · ${client.pendingActionCount} pending actions',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last active ${TimeFormat.lastActiveLabel(client.lastActiveTimestamp)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                  if (client.location.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(client.location, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (client.buyerMode == BuyerMode.privacy) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                client.privacyMessage ??
                    'Search insights are private. Showing requests are still shared.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Recent activity',
              icon: Icons.history,
              child: client.activities.isEmpty
                  ? const Text(
                      'No recent activity',
                      style: TextStyle(color: AppColors.muted),
                    )
                  : Column(
                      children: client.activities.map((ClientActivity activity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                _activityIcon(activity.type),
                                color: _activityColor(activity.type),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      activity.label,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      activity.description,
                                      style: const TextStyle(color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                TimeFormat.relative(activity.timestamp.toIso8601String()),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            _DetailSection(
              title: 'Action items',
              icon: Icons.task_alt_outlined,
              child: client.pendingActions.isEmpty
                  ? const Text(
                      'No Actions',
                      style: TextStyle(color: AppColors.muted),
                    )
                  : Column(
                      children: client.pendingActions.map((ClientAction action) {
                        return Card(
                          color: _priorityFill(action.priority, theme),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(action.label),
                            subtitle: Text(action.description),
                            trailing: TextButton(
                              onPressed: () {
                                ref
                                    .read(clientsControllerProvider.notifier)
                                    .markActionComplete(client.id, action.id);
                                Navigator.of(context).pop();
                              },
                              child: const Text('Mark Complete'),
                            ),
                            onTap: action.type == ClientActionType.showingRequested
                                ? () {
                                    ref
                                        .read(showingsInitialFilterProvider.notifier)
                                        .state = ShowingStatus.pending;
                                    Navigator.of(context).pop();
                                    StatefulNavigationShell.of(context).goBranch(3);
                                  }
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
            ),
            _DetailSection(
              title: 'Recent messages',
              icon: Icons.chat_bubble_outline,
              child: _conversation == null
                  ? const Text(
                      'No conversations yet.',
                      style: TextStyle(color: AppColors.muted),
                    )
                  : FutureBuilder<ClientConversation?>(
                      future: _conversation,
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<ClientConversation?> snapshot,
                      ) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Column(
                            children: <Widget>[
                              AppSkeletonBlock(height: 36, radius: 14),
                              SizedBox(height: 8),
                              AppSkeletonBlock(width: 180, height: 36, radius: 14),
                            ],
                          );
                        }
                        final List<ConversationMessage> messages =
                            snapshot.data?.messages ?? const <ConversationMessage>[];
                        if (messages.isEmpty) {
                          return const Text(
                            'No conversations yet.',
                            style: TextStyle(color: AppColors.muted),
                          );
                        }
                        return Column(
                          children: messages.reversed.take(5).map((ConversationMessage m) {
                            return Align(
                              alignment: m.isUser
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: m.isUser
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Text(
                                  m.text.trim().isEmpty
                                      ? 'Conversation activity'
                                      : m.text,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => showClientSearchHistorySheet(context, client),
              child: const Text('View Search History'),
            ),
          ],
        ),
    );
  }

  IconData _activityIcon(ActivityType type) {
    return switch (type) {
      ActivityType.propertySearch => Icons.search,
      ActivityType.propertyView => Icons.visibility_outlined,
      ActivityType.propertySave => Icons.favorite_outline,
      ActivityType.searchCriteriaUpdate => Icons.tune,
      ActivityType.messageSent => Icons.chat_bubble_outline,
    };
  }

  Color _activityColor(ActivityType type) {
    return switch (type) {
      ActivityType.propertySearch => AppColors.clients,
      ActivityType.propertyView => AppColors.showings,
      ActivityType.propertySave => AppColors.saved,
      ActivityType.searchCriteriaUpdate => AppColors.review,
      ActivityType.messageSent => AppColors.followup,
    };
  }

  Color _priorityFill(ActionPriority priority, ThemeData theme) {
    return switch (priority) {
      ActionPriority.high => AppColors.showingAction.withValues(alpha: 0.08),
      ActionPriority.medium => AppColors.followup.withValues(alpha: 0.08),
      ActionPriority.low => AppColors.inquiry.withValues(alpha: 0.08),
    };
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool light = theme.brightness == Brightness.light;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: light ? Colors.white : const Color(0xFF241C18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.label,
    this.icon,
    this.foreground = AppColors.ink,
    this.background = Colors.white,
  });

  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final bool light = Theme.of(context).brightness == Brightness.light;
    final bool neutral = background == Colors.white;
    final Color fill = neutral && !light ? const Color(0xFF2A221E) : background;
    final Color tone = neutral && !light ? Colors.white : foreground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: neutral
              ? (light ? const Color(0xFFE7E0DA) : const Color(0xFF4A4038))
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: tone),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
