import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
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
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => ClientDetailsSheet(client: client),
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
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: <Widget>[
            Text('Client Details', style: theme.textTheme.titleLarge),
            Text(
              'View client information, activity history, and recent messages',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(client.initials)),
              title: Text(client.name),
              subtitle: Text(
                <String>[
                  if (client.email.isNotEmpty) client.email,
                  if (client.phone.isNotEmpty) client.phone,
                ].join(' · '),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(client.statusLabel)),
                if (client.buyerMode == BuyerMode.sharing)
                  const Chip(
                    avatar: Icon(Icons.visibility, size: 16),
                    label: Text('Sharing'),
                  ),
                if (client.buyerMode == BuyerMode.privacy)
                  const Chip(
                    avatar: Icon(Icons.visibility_off, size: 16),
                    label: Text('Privacy'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${client.searches} searches · ${client.messages} messages · ${client.pendingActionCount} pending actions',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Last active ${TimeFormat.lastActiveLabel(client.lastActiveTimestamp)}',
              style: theme.textTheme.bodySmall,
            ),
            if (client.location.isNotEmpty) Text(client.location),
            if (client.buyerMode == BuyerMode.privacy) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                client.privacyMessage ??
                    'Search insights are private. Showing requests are still shared.',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Recent activity', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (client.activities.isEmpty)
              const Text('No recent activity')
            else
              ...client.activities.map((ClientActivity activity) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _activityIcon(activity.type),
                    color: _activityColor(activity.type),
                  ),
                  title: Text(activity.label),
                  subtitle: Text(activity.description),
                  trailing: Text(TimeFormat.relative(activity.timestamp.toIso8601String())),
                );
              }),
            const SizedBox(height: AppSpacing.md),
            Text('Action items', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (client.pendingActions.isEmpty)
              const Text('No Actions')
            else
              ...client.pendingActions.map((ClientAction action) {
                return Card(
                  color: _priorityFill(action.priority, theme),
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
              }),
            const SizedBox(height: AppSpacing.md),
            Text('Recent messages', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (_conversation == null)
              const Text('No conversations yet.')
            else
              FutureBuilder<ClientConversation?>(
                future: _conversation,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<ClientConversation?> snapshot,
                ) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final List<ConversationMessage> messages =
                      snapshot.data?.messages ?? const <ConversationMessage>[];
                  if (messages.isEmpty) {
                    return const Text('No conversations yet.');
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
                            m.text.trim().isEmpty ? 'Conversation activity' : m.text,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showClientSearchHistorySheet(context, client);
              },
              child: const Text('View Search History'),
            ),
          ],
        ),
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
