enum ClientUiStatus {
  invited,
  active,
  inactive,
  paused,
  archived,
  declined,
  revoked,
}

enum ActivityLevel { high, medium, low }

enum ActivityType {
  propertySearch,
  propertyView,
  propertySave,
  searchCriteriaUpdate,
  messageSent,
}

enum ClientActionType {
  showingRequested,
  needsFollowup,
  inquiryResponse,
  scheduleCallback,
  reviewCriteria,
}

enum ActionPriority { high, medium, low }

enum ActionItemStatus { pending, completed }

enum SortField { name, lastActive, activityLevel, createdAt, pendingActions }

enum ActionFilter {
  all,
  hasActions,
  highPriority,
  mediumPriority,
  lowPriority,
  showingRequested,
  needsFollowup,
  inquiryResponse,
  scheduleCallback,
  reviewCriteria,
}

enum BuyerMode { sharing, privacy }

final class ClientActivity {
  const ClientActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  final String id;
  final ActivityType type;
  final String description;
  final DateTime timestamp;

  String get label => switch (type) {
        ActivityType.propertySearch => 'Property Search',
        ActivityType.propertyView => 'Viewed Property',
        ActivityType.propertySave => 'Saved Property',
        ActivityType.searchCriteriaUpdate => 'Updated Search',
        ActivityType.messageSent => 'Sent Message',
      };
}

final class ClientAction {
  const ClientAction({
    required this.id,
    required this.type,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.propertyAddress,
  });

  final String id;
  final ClientActionType type;
  final String description;
  final ActionPriority priority;
  final ActionItemStatus status;
  final DateTime createdAt;
  final String? propertyAddress;

  bool get isPending => status == ActionItemStatus.pending;

  String get label => switch (type) {
        ClientActionType.showingRequested => 'Showing Requested',
        ClientActionType.needsFollowup => 'Needs Follow-up',
        ClientActionType.inquiryResponse => 'Respond to Inquiry',
        ClientActionType.scheduleCallback => 'Schedule Callback',
        ClientActionType.reviewCriteria => 'Review Criteria',
      };

  ClientAction copyWith({ActionItemStatus? status}) {
    return ClientAction(
      id: id,
      type: type,
      description: description,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      propertyAddress: propertyAddress,
    );
  }
}

final class RosterClient {
  const RosterClient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.lastActiveTimestamp,
    required this.createdAt,
    required this.searches,
    required this.messages,
    required this.activities,
    required this.actions,
    this.location = '',
    this.managedClientId,
    this.conversationId,
    this.buyerMode,
    this.privacyMessage,
    this.invitedAt,
    this.pausedAt,
    this.archivedAt,
    this.declinedAt,
    this.revokedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final ClientUiStatus status;
  final int lastActiveTimestamp;
  final DateTime createdAt;
  final int searches;
  final int messages;
  final List<ClientActivity> activities;
  final List<ClientAction> actions;
  final String location;
  final String? managedClientId;
  final String? conversationId;
  final BuyerMode? buyerMode;
  final String? privacyMessage;
  final DateTime? invitedAt;
  final DateTime? pausedAt;
  final DateTime? archivedAt;
  final DateTime? declinedAt;
  final DateTime? revokedAt;

  int get activityTotal => searches + messages;

  ActivityLevel get activityLevel {
    if (activityTotal >= 15) return ActivityLevel.high;
    if (activityTotal >= 5) return ActivityLevel.medium;
    return ActivityLevel.low;
  }

  List<ClientAction> get pendingActions =>
      actions.where((ClientAction a) => a.isPending).toList();

  int get pendingActionCount => pendingActions.length;

  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'C';
  }

  String get statusLabel => switch (status) {
        ClientUiStatus.revoked => 'Relation Revoked',
        ClientUiStatus.invited => 'Invited',
        ClientUiStatus.active => 'Active',
        ClientUiStatus.inactive => 'Inactive',
        ClientUiStatus.paused => 'Paused',
        ClientUiStatus.archived => 'Archived',
        ClientUiStatus.declined => 'Declined',
      };

  bool get canResendInvite =>
      managedClientId != null &&
      (status == ClientUiStatus.invited ||
          status == ClientUiStatus.declined ||
          status == ClientUiStatus.revoked ||
          status == ClientUiStatus.archived);

  bool get canDelete => managedClientId != null;

  bool get isSharingHidden => buyerMode == BuyerMode.privacy;

  RosterClient copyWith({
    ClientUiStatus? status,
    List<ClientAction>? actions,
    DateTime? pausedAt,
    DateTime? archivedAt,
  }) {
    return RosterClient(
      id: id,
      name: name,
      email: email,
      phone: phone,
      status: status ?? this.status,
      lastActiveTimestamp: lastActiveTimestamp,
      createdAt: createdAt,
      searches: searches,
      messages: messages,
      activities: activities,
      actions: actions ?? this.actions,
      location: location,
      managedClientId: managedClientId,
      conversationId: conversationId,
      buyerMode: buyerMode,
      privacyMessage: privacyMessage,
      invitedAt: invitedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      declinedAt: declinedAt,
      revokedAt: revokedAt,
    );
  }
}

final class ClientListQuery {
  const ClientListQuery({
    this.search = '',
    this.status,
    this.actionFilter = ActionFilter.all,
    this.recentlyAdded = false,
    this.sortField = SortField.name,
    this.sortAscending = true,
  });

  final String search;
  final ClientUiStatus? status;
  final ActionFilter actionFilter;
  final bool recentlyAdded;
  final SortField sortField;
  final bool sortAscending;

  bool get hasActiveFilters =>
      search.trim().isNotEmpty ||
      status != null ||
      actionFilter != ActionFilter.all ||
      recentlyAdded;

  ClientListQuery copyWith({
    String? search,
    ClientUiStatus? status,
    bool clearStatus = false,
    ActionFilter? actionFilter,
    bool? recentlyAdded,
    SortField? sortField,
    bool? sortAscending,
  }) {
    return ClientListQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      actionFilter: actionFilter ?? this.actionFilter,
      recentlyAdded: recentlyAdded ?? this.recentlyAdded,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

abstract final class ClientRosterQuery {
  static List<RosterClient> apply(
    List<RosterClient> clients,
    ClientListQuery query, {
    DateTime? now,
  }) {
    Iterable<RosterClient> next = clients;
    final String search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
      next = next.where(
        (RosterClient c) => c.name.toLowerCase().contains(search),
      );
    }
    if (query.status != null) {
      next = next.where((RosterClient c) => c.status == query.status);
    }
    if (query.actionFilter != ActionFilter.all) {
      next = next.where((RosterClient c) {
        final List<ClientAction> pending = c.pendingActions;
        switch (query.actionFilter) {
          case ActionFilter.hasActions:
            return pending.isNotEmpty;
          case ActionFilter.highPriority:
            return pending.any((ClientAction a) => a.priority == ActionPriority.high);
          case ActionFilter.mediumPriority:
            return pending.any((ClientAction a) => a.priority == ActionPriority.medium);
          case ActionFilter.lowPriority:
            return pending.any((ClientAction a) => a.priority == ActionPriority.low);
          case ActionFilter.showingRequested:
            return pending.any(
              (ClientAction a) => a.type == ClientActionType.showingRequested,
            );
          case ActionFilter.needsFollowup:
            return pending.any(
              (ClientAction a) => a.type == ClientActionType.needsFollowup,
            );
          case ActionFilter.inquiryResponse:
            return pending.any(
              (ClientAction a) => a.type == ClientActionType.inquiryResponse,
            );
          case ActionFilter.scheduleCallback:
            return pending.any(
              (ClientAction a) => a.type == ClientActionType.scheduleCallback,
            );
          case ActionFilter.reviewCriteria:
            return pending.any(
              (ClientAction a) => a.type == ClientActionType.reviewCriteria,
            );
          case ActionFilter.all:
            return true;
        }
      });
    }
    if (query.recentlyAdded) {
      final DateTime cutoff =
          (now ?? DateTime.now()).subtract(const Duration(days: 7));
      next = next.where((RosterClient c) => c.createdAt.isAfter(cutoff));
    }

    final List<RosterClient> sorted = next.toList()
      ..sort((RosterClient a, RosterClient b) {
        int comparison = 0;
        switch (query.sortField) {
          case SortField.name:
            comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortField.lastActive:
            comparison = a.lastActiveTimestamp.compareTo(b.lastActiveTimestamp);
          case SortField.activityLevel:
            comparison = a.activityTotal.compareTo(b.activityTotal);
          case SortField.createdAt:
            comparison = a.createdAt.compareTo(b.createdAt);
          case SortField.pendingActions:
            comparison = a.pendingActionCount.compareTo(b.pendingActionCount);
        }
        return query.sortAscending ? comparison : -comparison;
      });
    return sorted;
  }

  static int totalPendingActions(List<RosterClient> clients) {
    return clients.fold<int>(
      0,
      (int sum, RosterClient c) => sum + c.pendingActionCount,
    );
  }

  static int needsAttentionCount(List<RosterClient> clients) {
    return clients.where((RosterClient c) => c.pendingActionCount > 0).length;
  }

  static int countByType(List<RosterClient> clients, ClientActionType type) {
    return clients.fold<int>(0, (int sum, RosterClient c) {
      return sum +
          c.pendingActions
              .where((ClientAction a) => a.type == type)
              .length;
    });
  }
}
