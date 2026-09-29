import '../../../clients/domain/models/buyer_fields.dart';

enum ShowingStatus {
  pending,
  scheduled,
  completed,
  cancelled,
  declined,
}

extension ShowingStatusX on ShowingStatus {
  String get apiValue => name;

  String get label => switch (this) {
        ShowingStatus.pending => 'Pending',
        ShowingStatus.scheduled => 'Scheduled',
        ShowingStatus.completed => 'Completed',
        ShowingStatus.cancelled => 'Cancelled',
        ShowingStatus.declined => 'Declined',
      };

  String get markAsLabel => 'Mark as $label';

  static ShowingStatus parse(String? raw) {
    return ShowingStatus.values.firstWhere(
      (ShowingStatus s) => s.name == raw,
      orElse: () => ShowingStatus.pending,
    );
  }
}

/// `GET /v1/agent/showing-requests` row.
final class ShowingRequest {
  const ShowingRequest({
    required this.id,
    required this.buyerName,
    required this.status,
    this.propertyAddress,
    this.propertyCity,
    this.scheduledAt,
    this.buyerId,
    this.buyerEmail,
    this.buyerPhone,
    this.message,
    this.createdAt,
    this.propertyExternalId,
    this.propertyUrl,
    this.agentClientId,
  });

  final String id;
  final String buyerName;
  final String status;
  final String? propertyAddress;
  final String? propertyCity;
  final String? scheduledAt;
  final String? buyerId;
  final String? buyerEmail;
  final String? buyerPhone;
  final String? message;
  final String? createdAt;
  final String? propertyExternalId;
  final String? propertyUrl;
  final String? agentClientId;

  ShowingStatus get statusEnum => ShowingStatusX.parse(status);

  bool get isPending => status == 'pending';
  bool get isScheduled => status == 'scheduled' && scheduledAt != null;
  bool get canSchedule => isPending;
  bool get canReschedule =>
      status == 'scheduled' || status == 'cancelled' || status == 'declined';
  bool get canDecline => isPending;
  bool get hasMessage => (message ?? '').trim().isNotEmpty;
  bool get hasListingUrl => (propertyUrl ?? '').trim().isNotEmpty;
  bool get hasEmail => (buyerEmail ?? '').trim().isNotEmpty;
  bool get hasPhone => (buyerPhone ?? '').trim().isNotEmpty;

  DateTime? get scheduledAtDate =>
      scheduledAt == null ? null : DateTime.tryParse(scheduledAt!);

  String get displayBuyerName {
    final String name = buyerName.trim();
    if (name.isNotEmpty && name != 'A buyer') return name;
    if ((buyerEmail ?? '').trim().isNotEmpty) return buyerEmail!.trim();
    return '—';
  }

  String get listingTitle {
    final String address = (propertyAddress ?? '').trim();
    if (address.isNotEmpty) return address;
    final String external = (propertyExternalId ?? '').trim();
    if (external.isNotEmpty) return external;
    return 'this property';
  }

  String get propertyLabel {
    final String address = (propertyAddress ?? '').trim();
    if (address.isNotEmpty) return address;
    final String external = (propertyExternalId ?? '').trim();
    if (external.isNotEmpty) return external;
    final String city = (propertyCity ?? '').trim();
    if (city.isNotEmpty) return city;
    return 'Property details inside';
  }

  String get propertySubtitle {
    final String city = (propertyCity ?? '').trim();
    if (city.isEmpty) return '';
    final String title = listingTitle;
    if (title == city || title.endsWith(city)) return '';
    return city;
  }

  ShowingRequest copyWith({
    String? status,
    String? scheduledAt,
    bool clearScheduledAt = false,
  }) {
    return ShowingRequest(
      id: id,
      buyerName: buyerName,
      status: status ?? this.status,
      propertyAddress: propertyAddress,
      propertyCity: propertyCity,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      buyerId: buyerId,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
      message: message,
      createdAt: createdAt,
      propertyExternalId: propertyExternalId,
      propertyUrl: propertyUrl,
      agentClientId: agentClientId,
    );
  }

  factory ShowingRequest.fromJson(Map<String, dynamic> json) {
    final BuyerFields buyer = BuyerFields.parse(json['buyerId']);
    final String name = buyer.name.isNotEmpty
        ? buyer.name
        : (buyer.email.isNotEmpty ? buyer.email : '—');
    return ShowingRequest(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      buyerName: name,
      status: (json['status'] as String?) ?? 'pending',
      propertyAddress: json['propertyAddress'] as String?,
      propertyCity: json['propertyCity'] as String?,
      scheduledAt: json['scheduledAt'] as String?,
      buyerId: buyer.id.isEmpty ? null : buyer.id,
      buyerEmail: buyer.email.isEmpty ? null : buyer.email,
      buyerPhone: buyer.phone.isEmpty ? null : buyer.phone,
      message: json['message'] as String?,
      createdAt: json['createdAt'] as String?,
      propertyExternalId: json['propertyExternalId'] as String?,
      propertyUrl: json['propertyUrl'] as String?,
      agentClientId: json['agentClientId']?.toString(),
    );
  }
}

abstract final class ShowingSchedule {
  static const TimeParts defaultTime = TimeParts(10, 0);

  static String? validate({
    required DateTime? date,
    required TimeParts time,
    DateTime? now,
  }) {
    if (date == null) return 'Pick a visit date first.';
    final DateTime combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!combined.isAfter(now ?? DateTime.now())) {
      return 'Please choose a future date and time for the visit.';
    }
    return null;
  }

  static bool isPastOnDate(DateTime date, TimeParts time, DateTime now) {
    final DateTime combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return !combined.isAfter(now);
  }

  static DateTime combine(DateTime date, TimeParts time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

final class TimeParts {
  const TimeParts(this.hour, this.minute);

  final int hour;
  final int minute;
}

final class ShowingCounts {
  const ShowingCounts({
    required this.total,
    required this.pending,
    required this.scheduled,
    required this.completed,
    required this.cancelled,
  });

  final int total;
  final int pending;
  final int scheduled;
  final int completed;
  final int cancelled;

  factory ShowingCounts.from(List<ShowingRequest> list) {
    int pending = 0;
    int scheduled = 0;
    int completed = 0;
    int cancelled = 0;
    for (final ShowingRequest item in list) {
      switch (item.statusEnum) {
        case ShowingStatus.pending:
          pending += 1;
        case ShowingStatus.scheduled:
          scheduled += 1;
        case ShowingStatus.completed:
          completed += 1;
        case ShowingStatus.cancelled:
        case ShowingStatus.declined:
          cancelled += 1;
      }
    }
    return ShowingCounts(
      total: list.length,
      pending: pending,
      scheduled: scheduled,
      completed: completed,
      cancelled: cancelled,
    );
  }
}
