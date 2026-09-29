import '../../showings/domain/models/showing_request.dart';
import 'models/client_conversation.dart';
import 'models/client_interest.dart';
import 'models/managed_client.dart';
import 'models/roster_client.dart';

final class ClientRoster {
  const ClientRoster({
    required this.clients,
    required this.pendingRequests,
  });

  final List<RosterClient> clients;
  final List<ManagedClient> pendingRequests;
}

/// Mirrors web `clients-page.tsx` hydration (spec §5.6).
abstract final class ClientRosterMerger {
  static const Duration _followUpAfter = Duration(days: 14);

  static ClientRoster merge({
    required List<ClientInterest> interests,
    required List<ClientConversation> conversations,
    required List<ManagedClient> managed,
    required List<ShowingRequest> showings,
    DateTime? now,
  }) {
    final DateTime clock = now ?? DateTime.now();
    final Map<String, ClientConversation> convoByBuyer =
        <String, ClientConversation>{};
    for (final ClientConversation convo in conversations) {
      if (convo.buyerId.isNotEmpty) {
        convoByBuyer[convo.buyerId] = convo;
      }
    }

    final Map<String, RosterClient> byBuyer = <String, RosterClient>{};

    for (final ClientInterest interest in interests) {
      if (interest.buyerId.isEmpty) continue;
      final ClientConversation? convo = convoByBuyer[interest.buyerId];
      final DateTime? lastActive = _parse(
        convo?.lastMessageAt ?? convo?.updatedAt ?? interest.updatedAt ?? interest.createdAt,
      );
      final DateTime created = _parse(interest.createdAt) ?? clock;
      final List<ConversationMessage> messages = convo?.messages ?? const <ConversationMessage>[];
      final int searches = messages.where((ConversationMessage m) => m.isUser).length;
      final List<ClientActivity> activities = messages.reversed.take(3).toList().asMap().entries.map((entry) {
        final ConversationMessage m = entry.value;
        return ClientActivity(
          id: '${interest.buyerId}-act-${entry.key}',
          type: m.isUser
              ? ActivityType.messageSent
              : ActivityType.searchCriteriaUpdate,
          description: m.text.trim().isEmpty
              ? 'Conversation activity'
              : (m.text.length > 140 ? m.text.substring(0, 140) : m.text),
          timestamp: lastActive ?? clock,
        );
      }).toList();

      final ClientUiStatus status = interest.status == 'closed'
          ? ClientUiStatus.archived
          : ClientUiStatus.active;

      final List<ClientAction> actions = <ClientAction>[];
      if ((interest.message ?? '').trim().isNotEmpty && interest.status != 'closed') {
        actions.add(
          ClientAction(
            id: '${interest.buyerId}-inquiry',
            type: ClientActionType.inquiryResponse,
            description: interest.message!.length > 160
                ? interest.message!.substring(0, 160)
                : interest.message!,
            priority: ActionPriority.medium,
            status: ActionItemStatus.pending,
            createdAt: _parse(interest.updatedAt ?? interest.createdAt) ?? clock,
          ),
        );
      }
      if (lastActive != null &&
          clock.difference(lastActive) > _followUpAfter &&
          interest.status != 'closed') {
        actions.add(
          ClientAction(
            id: '${interest.buyerId}-followup',
            type: ClientActionType.needsFollowup,
            description: 'No recent activity - follow up needed',
            priority: ActionPriority.medium,
            status: ActionItemStatus.pending,
            createdAt: clock,
          ),
        );
      }

      final RosterClient? existing = byBuyer[interest.buyerId];
      if (existing != null) {
        byBuyer[interest.buyerId] = existing.copyWith(
          actions: <ClientAction>[...existing.actions, ...actions],
        );
        continue;
      }

      byBuyer[interest.buyerId] = RosterClient(
        id: interest.buyerId,
        name: interest.name,
        email: interest.email,
        phone: interest.phone,
        status: status,
        lastActiveTimestamp: lastActive?.millisecondsSinceEpoch ?? 0,
        createdAt: created,
        searches: searches,
        messages: messages.length,
        activities: activities,
        actions: actions,
        conversationId: convo?.id,
      );
    }

    for (final ClientConversation convo in conversations) {
      if (convo.buyerId.isEmpty || byBuyer.containsKey(convo.buyerId)) continue;
      final DateTime? lastActive = _parse(convo.lastMessageAt ?? convo.updatedAt);
      final int searches =
          convo.messages.where((ConversationMessage m) => m.isUser).length;
      byBuyer[convo.buyerId] = RosterClient(
        id: convo.buyerId,
        name: convo.name,
        email: convo.email,
        phone: convo.phone,
        status: ClientUiStatus.active,
        lastActiveTimestamp: lastActive?.millisecondsSinceEpoch ?? 0,
        createdAt: lastActive ?? clock,
        searches: searches,
        messages: convo.messages.length,
        activities: const <ClientActivity>[],
        actions: const <ClientAction>[],
        conversationId: convo.id,
      );
    }

    for (final ManagedClient mc in managed) {
      if (mc.id.isEmpty || mc.isPending) continue;
      final ClientUiStatus status = switch (mc.status) {
        'revoked' => ClientUiStatus.revoked,
        'archived' => ClientUiStatus.archived,
        'invited' => ClientUiStatus.invited,
        'declined' => ClientUiStatus.declined,
        _ => ClientUiStatus.active,
      };
      final DateTime created = _parse(mc.createdAt) ?? clock;
      final DateTime? updated = _parse(mc.updatedAt);
      final BuyerMode? buyerMode = switch (mc.shareSearchInsights) {
        false => BuyerMode.privacy,
        true => BuyerMode.sharing,
        null => null,
      };
      final String? linked = (mc.buyerId ?? '').trim().isEmpty ? null : mc.buyerId;
      if (linked != null && byBuyer.containsKey(linked)) {
        final RosterClient existing = byBuyer[linked]!;
        byBuyer[linked] = RosterClient(
          id: existing.id,
          name: existing.name,
          email: existing.email,
          phone: existing.phone.isNotEmpty ? existing.phone : mc.phone,
          status: status,
          lastActiveTimestamp: existing.lastActiveTimestamp,
          createdAt: existing.createdAt,
          searches: existing.searches,
          messages: existing.messages,
          activities: existing.activities,
          actions: existing.actions,
          location: existing.location,
          managedClientId: mc.id,
          conversationId: existing.conversationId,
          buyerMode: buyerMode,
          privacyMessage: mc.privacyMessage ?? existing.privacyMessage,
          invitedAt: _parse(mc.invitedAt) ?? existing.invitedAt,
          declinedAt: _parse(mc.inviteDeclinedAt) ?? existing.declinedAt,
          revokedAt: _parse(mc.revokedAt) ?? existing.revokedAt,
          pausedAt: existing.pausedAt,
          archivedAt: existing.archivedAt,
        );
        continue;
      }
      if (byBuyer.containsKey(mc.id)) continue;
      byBuyer[mc.id] = RosterClient(
        id: mc.id,
        name: mc.displayName,
        email: mc.email,
        phone: mc.phone,
        status: status,
        lastActiveTimestamp:
            (updated ?? created).millisecondsSinceEpoch,
        createdAt: created,
        searches: 0,
        messages: 0,
        activities: const <ClientActivity>[],
        actions: const <ClientAction>[],
        managedClientId: mc.id,
        buyerMode: buyerMode,
        privacyMessage: mc.privacyMessage,
        invitedAt: _parse(mc.invitedAt),
        declinedAt: _parse(mc.inviteDeclinedAt),
        revokedAt: _parse(mc.revokedAt),
      );
    }

    for (final ShowingRequest showing in showings) {
      if (!showing.isPending) continue;
      final ClientAction action = ClientAction(
        id: '${showing.buyerId ?? showing.id}-showing-${showing.id}',
        type: ClientActionType.showingRequested,
        description: _showingDescription(showing),
        priority: ActionPriority.high,
        status: ActionItemStatus.pending,
        createdAt: _parse(showing.createdAt) ?? clock,
        propertyAddress: showing.propertyAddress,
      );
      final RosterClient? match = _matchShowing(byBuyer, showing);
      if (match != null) {
        if (match.actions.any((ClientAction a) => a.id == action.id)) continue;
        byBuyer[match.id] = match.copyWith(
          actions: <ClientAction>[...match.actions, action],
        );
        continue;
      }
      final String id = (showing.buyerId ?? showing.id).toString();
      if (id.isEmpty) continue;
      byBuyer[id] = RosterClient(
        id: id,
        name: showing.buyerName,
        email: showing.buyerEmail ?? '',
        phone: showing.buyerPhone ?? '',
        status: ClientUiStatus.active,
        lastActiveTimestamp: action.createdAt.millisecondsSinceEpoch,
        createdAt: action.createdAt,
        searches: 0,
        messages: 0,
        activities: const <ClientActivity>[],
        actions: <ClientAction>[action],
      );
    }

    return ClientRoster(
      clients: byBuyer.values.toList(),
      pendingRequests: managed.where((ManagedClient c) => c.isPending).toList(),
    );
  }

  static RosterClient? _matchShowing(
    Map<String, RosterClient> byBuyer,
    ShowingRequest showing,
  ) {
    final String? buyerId = showing.buyerId;
    if (buyerId != null && byBuyer.containsKey(buyerId)) {
      return byBuyer[buyerId];
    }
    final String? agentClientId = showing.agentClientId;
    if (agentClientId != null && agentClientId.isNotEmpty) {
      for (final RosterClient client in byBuyer.values) {
        if (client.managedClientId == agentClientId) return client;
      }
    }
    final String email = (showing.buyerEmail ?? '').trim().toLowerCase();
    if (email.isNotEmpty) {
      for (final RosterClient client in byBuyer.values) {
        if (client.email.trim().toLowerCase() == email) return client;
      }
    }
    return null;
  }

  static String _showingDescription(ShowingRequest showing) {
    final String property = showing.propertyAddress?.trim().isNotEmpty == true
        ? showing.propertyAddress!
        : (showing.propertyExternalId ?? 'a property');
    final String base = 'Requested property showing — $property';
    final String? message = showing.message?.trim();
    if (message == null || message.isEmpty) return base;
    final String clipped = message.length > 120 ? message.substring(0, 120) : message;
    return '$base: $clipped';
  }

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
