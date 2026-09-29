import 'package:flutter/material.dart';

enum InsightTone { info, warning, good, watch, concern, neutral }

enum AnalyticsRange {
  months3(3, 'Last 3 months'),
  months6(6, 'Last 6 months'),
  months12(12, 'Last 12 months');

  const AnalyticsRange(this.months, this.label);
  final int months;
  final String label;

  static AnalyticsRange fromMonths(int months) {
    return AnalyticsRange.values.firstWhere(
      (AnalyticsRange r) => r.months == months,
      orElse: () => AnalyticsRange.months6,
    );
  }
}

final class AnalyticsClient {
  const AnalyticsClient({
    required this.id,
    required this.agentClientId,
    required this.name,
    required this.email,
    this.status = '',
    this.analyticsEnabled = true,
  });

  final String id;
  final String agentClientId;
  final String name;
  final String email;
  final String status;
  final bool analyticsEnabled;

  String get pickerLabel =>
      analyticsEnabled ? name : '$name (Sharing Disabled)';

  factory AnalyticsClient.fromJson(Map<String, dynamic> json) {
    return AnalyticsClient(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      agentClientId: (json['agentClientId'] ?? '').toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Client',
      email: (json['email'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      analyticsEnabled: json['analyticsEnabled'] != false,
    );
  }
}

final class StatMetric {
  const StatMetric({
    required this.value,
    this.deltaPct,
    this.window,
    this.unit,
    this.label,
    this.pending,
    this.scheduled,
    this.completed,
    this.cancelled,
    this.declined,
    this.lifetime,
  });

  final num value;
  final num? deltaPct;
  final String? window;
  final String? unit;
  final String? label;
  final num? pending;
  final num? scheduled;
  final num? completed;
  final num? cancelled;
  final num? declined;
  final num? lifetime;

  String get valueLabel => '$value${unit ?? ''}';

  String? get deltaLabel {
    if (deltaPct == null) return null;
    final String arrow = deltaPct! >= 0 ? '↑' : '↓';
    return '$arrow ${deltaPct!.abs()}%';
  }

  bool get deltaUp => (deltaPct ?? 0) >= 0;

  String get viewingRequestsDetail {
    final List<String> parts = <String>[];
    if ((pending ?? 0) != 0) parts.add('$pending pending');
    if ((scheduled ?? 0) != 0) parts.add('$scheduled scheduled');
    if ((completed ?? 0) != 0) parts.add('$completed completed');
    if ((cancelled ?? 0) != 0) parts.add('$cancelled cancelled');
    if ((declined ?? 0) != 0) parts.add('$declined declined');
    return parts.isEmpty ? 'No requests yet' : parts.join(', ');
  }

  String get zeroResultDetail {
    final String base = label ?? '';
    if (lifetime == null) return base;
    final String life = 'lifetime $lifetime%';
    return base.isEmpty ? '· $life' : '$base · $life';
  }

  factory StatMetric.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StatMetric(value: 0);
    return StatMetric(
      value: (json['value'] as num?) ?? 0,
      deltaPct: json['deltaPct'] as num?,
      window: json['window'] as String?,
      unit: json['unit'] as String?,
      label: json['label'] as String?,
      pending: json['pending'] as num?,
      scheduled: json['scheduled'] as num?,
      completed: json['completed'] as num?,
      cancelled: json['cancelled'] as num?,
      declined: json['declined'] as num?,
      lifetime: json['lifetime'] as num?,
    );
  }
}

final class AnalyticsStats {
  const AnalyticsStats({
    required this.totalSearches,
    required this.propertiesViewed,
    required this.viewingRequests,
    required this.zeroResultSearches,
    required this.favorites,
    required this.compared,
  });

  final StatMetric totalSearches;
  final StatMetric propertiesViewed;
  final StatMetric viewingRequests;
  final StatMetric zeroResultSearches;
  final StatMetric favorites;
  final StatMetric compared;

  factory AnalyticsStats.fromJson(Map<String, dynamic>? json) {
    return AnalyticsStats(
      totalSearches: StatMetric.fromJson(json?['totalSearches'] as Map<String, dynamic>?),
      propertiesViewed:
          StatMetric.fromJson(json?['propertiesViewed'] as Map<String, dynamic>?),
      viewingRequests:
          StatMetric.fromJson(json?['viewingRequests'] as Map<String, dynamic>?),
      zeroResultSearches:
          StatMetric.fromJson(json?['zeroResultSearches'] as Map<String, dynamic>?),
      favorites: StatMetric.fromJson(json?['favorites'] as Map<String, dynamic>?),
      compared: StatMetric.fromJson(json?['compared'] as Map<String, dynamic>?),
    );
  }
}

final class AiInsight {
  const AiInsight({required this.tone, required this.text});

  final InsightTone tone;
  final String text;

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      tone: (json['tone'] as String?) == 'warning'
          ? InsightTone.warning
          : InsightTone.info,
      text: (json['text'] as String?) ?? '',
    );
  }
}

final class AiSummary {
  const AiSummary({
    required this.summary,
    required this.highlights,
    this.analyticsEnabled = true,
  });

  final String summary;
  final List<AiInsight> highlights;
  final bool analyticsEnabled;

  factory AiSummary.fromJson(Map<String, dynamic> json) {
    return AiSummary(
      summary: (json['summary'] as String?) ?? '',
      highlights: (json['highlights'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AiInsight.fromJson)
          .toList(),
      analyticsEnabled: json['analyticsEnabled'] != false,
    );
  }
}

final class SearchActivityPoint {
  const SearchActivityPoint({
    required this.month,
    required this.searches,
    required this.zeroResults,
  });

  final String month;
  final num searches;
  final num zeroResults;

  factory SearchActivityPoint.fromJson(Map<String, dynamic> json) {
    return SearchActivityPoint(
      month: (json['month'] as String?) ?? '',
      searches: (json['searches'] as num?) ?? 0,
      zeroResults: (json['zeroResults'] as num?) ?? 0,
    );
  }
}

final class LocationSlice {
  const LocationSlice({
    required this.name,
    required this.value,
    required this.count,
  });

  final String name;
  final num value;
  final num count;

  factory LocationSlice.fromJson(Map<String, dynamic> json) {
    return LocationSlice(
      name: (json['name'] as String?) ?? '',
      value: (json['value'] as num?) ?? 0,
      count: (json['count'] as num?) ?? 0,
    );
  }
}

final class CriteriaChangeEntry {
  const CriteriaChangeEntry({
    required this.change,
    required this.date,
    this.field,
    this.fieldLabel,
    this.action,
    this.value,
    this.previous,
    this.createdAt,
  });

  final String change;
  final String date;
  final String? field;
  final String? fieldLabel;
  final String? action;
  final String? value;
  final String? previous;
  final String? createdAt;

  String get displayLabel =>
      ((fieldLabel ?? field) ?? 'Criteria').toLowerCase();

  String get actionVerb => switch (action) {
        'added' => 'added',
        'removed' => 'removed',
        _ => 'updated',
      };

  factory CriteriaChangeEntry.fromJson(Map<String, dynamic> json) {
    return CriteriaChangeEntry(
      change: (json['change'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      field: json['field'] as String?,
      fieldLabel: json['fieldLabel'] as String?,
      action: json['action'] as String?,
      value: json['value'] as String?,
      previous: json['previous'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

final class FunnelStage {
  const FunnelStage({required this.stage, required this.value});

  final String stage;
  final num value;

  factory FunnelStage.fromJson(Map<String, dynamic> json) {
    return FunnelStage(
      stage: (json['stage'] as String?) ?? '',
      value: (json['value'] as num?) ?? 0,
    );
  }
}

final class CriteriaUncertainty {
  const CriteriaUncertainty({
    required this.criteria,
    required this.totalChanges,
    required this.currentImportance,
    this.currentFlexibility = 'no',
  });

  final String criteria;
  final num totalChanges;
  final num currentImportance;
  final String currentFlexibility;

  factory CriteriaUncertainty.fromJson(Map<String, dynamic> json) {
    return CriteriaUncertainty(
      criteria: (json['criteria'] as String?) ?? '',
      totalChanges: (json['totalChanges'] as num?) ?? 0,
      currentImportance: (json['currentImportance'] as num?) ?? 0,
      currentFlexibility: (json['currentFlexibility'] as String?) ?? 'no',
    );
  }
}

final class NamedCount {
  const NamedCount({required this.name, required this.value, this.color});

  final String name;
  final num value;
  final String? color;

  factory NamedCount.fromJson(
    Map<String, dynamic> json, {
    String nameKey = 'name',
    String valueKey = 'value',
  }) {
    return NamedCount(
      name: (json[nameKey] as String?) ?? (json['bucket'] as String?) ?? '',
      value: (json[valueKey] as num?) ?? (json['count'] as num?) ?? 0,
      color: json['color'] as String?,
    );
  }
}

final class ViewEngagement {
  const ViewEngagement({
    required this.type,
    required this.avgSeconds,
    required this.views,
  });

  final String type;
  final num avgSeconds;
  final num views;

  factory ViewEngagement.fromJson(Map<String, dynamic> json) {
    return ViewEngagement(
      type: (json['type'] as String?) ?? '',
      avgSeconds: (json['avgSeconds'] as num?) ?? 0,
      views: (json['views'] as num?) ?? 0,
    );
  }
}

final class DailyCriteriaPoint {
  const DailyCriteriaPoint({
    required this.date,
    required this.day,
    required this.changes,
    required this.cumulativeChanges,
    this.isAfterFourWeeks = false,
    this.isLowActivity = false,
  });

  final String date;
  final String day;
  final num changes;
  final num cumulativeChanges;
  final bool isAfterFourWeeks;
  final bool isLowActivity;

  factory DailyCriteriaPoint.fromJson(Map<String, dynamic> json) {
    return DailyCriteriaPoint(
      date: (json['date'] as String?) ?? '',
      day: (json['day'] as String?) ?? '',
      changes: (json['changes'] as num?) ?? 0,
      cumulativeChanges: (json['cumulativeChanges'] as num?) ?? 0,
      isAfterFourWeeks: json['isAfterFourWeeks'] == true,
      isLowActivity: json['isLowActivity'] == true,
    );
  }
}

final class AnalyticsOverview {
  const AnalyticsOverview({
    required this.analyticsEnabled,
    required this.stats,
    this.searchActivity = const <SearchActivityPoint>[],
    this.locationDistribution = const <LocationSlice>[],
    this.recentCriteriaChanges = const <CriteriaChangeEntry>[],
    this.criteriaUncertainty = const <CriteriaUncertainty>[],
    this.engagementFunnel = const <FunnelStage>[],
    this.activityHeatmap = const <List<num>>[],
    this.resultQuality = const <NamedCount>[],
    this.viewEngagement = const <ViewEngagement>[],
    this.showingStatus = const <NamedCount>[],
    this.criteriaChangesDaily = const <DailyCriteriaPoint>[],
    this.aiInsights = const <AiInsight>[],
  });

  final bool analyticsEnabled;
  final AnalyticsStats stats;
  final List<SearchActivityPoint> searchActivity;
  final List<LocationSlice> locationDistribution;
  final List<CriteriaChangeEntry> recentCriteriaChanges;
  final List<CriteriaUncertainty> criteriaUncertainty;
  final List<FunnelStage> engagementFunnel;
  final List<List<num>> activityHeatmap;
  final List<NamedCount> resultQuality;
  final List<ViewEngagement> viewEngagement;
  final List<NamedCount> showingStatus;
  final List<DailyCriteriaPoint> criteriaChangesDaily;
  final List<AiInsight> aiInsights;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      analyticsEnabled: json['analyticsEnabled'] != false,
      stats: AnalyticsStats.fromJson(json['stats'] as Map<String, dynamic>?),
      searchActivity: _maps(json['searchActivity']).map(SearchActivityPoint.fromJson).toList(),
      locationDistribution:
          _maps(json['locationDistribution']).map(LocationSlice.fromJson).toList(),
      recentCriteriaChanges:
          _maps(json['recentCriteriaChanges']).map(CriteriaChangeEntry.fromJson).toList(),
      criteriaUncertainty:
          _maps(json['criteriaUncertainty']).map(CriteriaUncertainty.fromJson).toList(),
      engagementFunnel: _maps(json['engagementFunnel']).map(FunnelStage.fromJson).toList(),
      activityHeatmap: _heatmap(json['activityHeatmap']),
      resultQuality: _maps(json['resultQualityDistribution'])
          .map((Map<String, dynamic> e) => NamedCount.fromJson(e, nameKey: 'bucket', valueKey: 'count'))
          .toList(),
      viewEngagement: _maps(json['viewEngagement']).map(ViewEngagement.fromJson).toList(),
      showingStatus: _maps(json['showingStatusDistribution']).map(NamedCount.fromJson).toList(),
      criteriaChangesDaily:
          _maps(json['criteriaChangesDaily']).map(DailyCriteriaPoint.fromJson).toList(),
      aiInsights: _maps(json['aiInsights']).map(AiInsight.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  static List<List<num>> _heatmap(dynamic raw) {
    if (raw is! List) return const <List<num>>[];
    return raw
        .whereType<List<dynamic>>()
        .map((List<dynamic> row) => row.whereType<num>().toList())
        .toList();
  }
}

final class ChartInsight {
  const ChartInsight({required this.tone, required this.message});

  final InsightTone tone;
  final String message;
}

abstract final class AnalyticsInsights {
  static ChartInsight searchActivity(List<SearchActivityPoint> points) {
    final num totalSearches =
        points.fold<num>(0, (num a, SearchActivityPoint b) => a + b.searches);
    final num totalZero =
        points.fold<num>(0, (num a, SearchActivityPoint b) => a + b.zeroResults);
    if (totalSearches == 0) {
      return const ChartInsight(
        tone: InsightTone.neutral,
        message: 'No searches in this window yet.',
      );
    }
    final int zeroPct = ((totalZero / totalSearches) * 100).round();
    final int half = points.isEmpty ? 1 : (points.length / 2).floor().clamp(1, points.length);
    final num earlier = points
        .take(half)
        .fold<num>(0, (num a, SearchActivityPoint b) => a + b.searches);
    final num later = points
        .skip(points.length - half)
        .fold<num>(0, (num a, SearchActivityPoint b) => a + b.searches);
    final int trendPct = earlier == 0 ? 0 : (((later - earlier) / earlier) * 100).round();

    if (zeroPct >= 25) {
      return ChartInsight(
        tone: InsightTone.concern,
        message:
            '$zeroPct% of searches returned nothing. Tighten or loosen criteria with the buyer.',
      );
    }
    if (later == 0 && earlier > 0) {
      return const ChartInsight(
        tone: InsightTone.concern,
        message: 'Search activity has stopped recently — buyer may have disengaged.',
      );
    }
    if (trendPct <= -50 && earlier >= 5) {
      return ChartInsight(
        tone: InsightTone.watch,
        message: 'Search volume is down ${trendPct.abs()}% vs. earlier in the window.',
      );
    }
    if (trendPct >= 50) {
      return ChartInsight(
        tone: InsightTone.good,
        message: 'Search activity is up $trendPct% vs. earlier — buyer is heating up.',
      );
    }
    if (zeroPct >= 10) {
      return ChartInsight(
        tone: InsightTone.watch,
        message:
            '$zeroPct% of searches yield no results — a few criteria may need loosening.',
      );
    }
    return const ChartInsight(
      tone: InsightTone.good,
      message: 'Searches are productive — most return matches and activity is steady.',
    );
  }

  static ChartInsight location(List<LocationSlice> slices) {
    if (slices.isEmpty) {
      return const ChartInsight(
        tone: InsightTone.neutral,
        message: 'No location activity yet.',
      );
    }
    final List<LocationSlice> sorted = slices.toList()
      ..sort((LocationSlice a, LocationSlice b) => b.value.compareTo(a.value));
    final LocationSlice top = sorted.first;
    if (top.value >= 60) {
      return ChartInsight(
        tone: InsightTone.good,
        message:
            'Clearly focused on ${top.name} (${top.value}% of activity) — strong neighborhood signal.',
      );
    }
    if (sorted.length >= 5 && top.value <= 30) {
      return ChartInsight(
        tone: InsightTone.watch,
        message:
            'Activity spread across ${sorted.length} areas with no clear winner — help narrow to 2–3 neighborhoods.',
      );
    }
    return ChartInsight(
      tone: InsightTone.good,
      message: '${top.name} leads at ${top.value}% — a few neighborhoods dominate.',
    );
  }

  static ChartInsight recentChanges(List<CriteriaChangeEntry> entries) {
    if (entries.isEmpty) {
      return const ChartInsight(
        tone: InsightTone.good,
        message: 'No recent criteria churn — buyer is sticking with their picks.',
      );
    }
    if (entries.length >= 10) {
      return ChartInsight(
        tone: InsightTone.concern,
        message:
            '${entries.length} criteria changes lately — preferences are still in flux. Pause sending listings until priorities settle.',
      );
    }
    if (entries.length >= 5) {
      return ChartInsight(
        tone: InsightTone.watch,
        message:
            '${entries.length} recent changes — keep an eye on what’s shifting before sending the next batch.',
      );
    }
    final String noun = entries.length == 1 ? '' : 's';
    return ChartInsight(
      tone: InsightTone.good,
      message: '${entries.length} small tweak$noun — criteria are largely stable.',
    );
  }
}

abstract final class AnalyticsPalette {
  static const List<Color> series = <Color>[
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFFF43F5E),
    Color(0xFFA78BFA),
  ];

  static const Color primarySeries = Color(0xFF6366F1);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color neutral = Color(0xFF94A3B8);
  static const Color highlightWarning = Color(0xFFEF4444);

  static Color at(int index) => series[index % series.length];
}
