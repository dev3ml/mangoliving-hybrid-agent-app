import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/analytics_models.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsAiCard extends StatelessWidget {
  const AnalyticsAiCard({super.key, required this.view});

  final AnalyticsViewData view;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AnalyticsOverview? overview = view.overview;
    final List<AiInsight> highlights = view.ai?.highlights.isNotEmpty == true
        ? view.ai!.highlights
        : (view.aiFailed || view.ai == null
            ? (overview?.aiInsights ?? const <AiInsight>[])
            : const <AiInsight>[]);

    final bool light = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? const <Color>[Color(0xFFFFF1E6), Color(0xFFFFF7F2)]
              : const <Color>[Color(0xFF3A2418), Color(0xFF241C18)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI-Powered Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (view.aiLoading)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSkeletonBlock(height: 12),
                SizedBox(height: 8),
                AppSkeletonBlock(width: 180, height: 12),
              ],
            )
          else ...<Widget>[
            if (view.aiFailed)
              Text(
                overview?.aiInsights.isNotEmpty == true
                    ? 'AI summary is unavailable right now. Showing key signals instead.'
                    : 'AI summary is unavailable right now.',
                style: theme.textTheme.bodySmall,
              ),
            if ((view.ai?.summary ?? '').isNotEmpty) ...<Widget>[
              if (view.aiFailed) const SizedBox(height: AppSpacing.sm),
              Text(view.ai!.summary, style: theme.textTheme.bodyMedium),
            ],
            if (!view.aiLoading &&
                highlights.isEmpty &&
                (view.ai?.summary ?? '').isEmpty)
              Text(
                'Not enough activity yet to generate insights for this client.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (highlights.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              ...highlights.map((AiInsight insight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: insight.tone == InsightTone.warning
                              ? AnalyticsPalette.highlightWarning
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(insight.text)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class AnalyticsStatGrid extends StatelessWidget {
  const AnalyticsStatGrid({super.key, required this.stats});

  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = <Widget>[
      _StatTile(title: 'Total Searches', metric: stats.totalSearches),
      _StatTile(title: 'Properties Viewed', metric: stats.propertiesViewed),
      _StatTile(
        title: 'Viewing Requests',
        metric: stats.viewingRequests,
        detail: stats.viewingRequests.viewingRequestsDetail,
      ),
      _StatTile(
        title: 'Zero-Result Searches',
        metric: stats.zeroResultSearches,
        valueOverride: stats.zeroResultSearches.valueLabel,
        detail: stats.zeroResultSearches.zeroResultDetail,
      ),
      _StatTile(title: 'Favorites', metric: stats.favorites),
      _StatTile(title: 'Compared', metric: stats.compared),
    ];
    return Column(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: tiles[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.metric,
    this.detail,
    this.valueOverride,
  });

  final String title;
  final StatMetric metric;
  final String? detail;
  final String? valueOverride;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool light = theme.brightness == Brightness.light;
    final String? delta = metric.deltaLabel;
    final Color deltaColor =
        metric.deltaUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: light ? Colors.white : const Color(0xFF241C18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: light ? const Color(0xFFE7E5E4) : const Color(0xFF3A2E28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            valueOverride ?? '${metric.value}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          if (delta != null)
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: delta,
                    style: TextStyle(color: deltaColor, fontWeight: FontWeight.w600),
                  ),
                  if ((metric.window ?? '').isNotEmpty)
                    TextSpan(text: ' ${metric.window}'),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else if ((detail ?? metric.window ?? '').isNotEmpty)
            Text(
              detail ?? metric.window ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class AnalyticsChartCard extends StatelessWidget {
  const AnalyticsChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.insight,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final ChartInsight? insight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            child,
            if (insight != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                insight!.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AnalyticsHeatmap extends StatefulWidget {
  const AnalyticsHeatmap({super.key, required this.grid});

  final List<List<num>> grid;

  @override
  State<AnalyticsHeatmap> createState() => _AnalyticsHeatmapState();
}

class _AnalyticsHeatmapState extends State<AnalyticsHeatmap> {
  int? _day;
  int? _hour;

  static const List<String> _days = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<List<num>> rows = _padded(widget.grid);
    num max = 0;
    num total = 0;
    for (final List<num> row in rows) {
      for (final num cell in row) {
        total += cell;
        if (cell > max) max = cell;
      }
    }
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'No activity recorded yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final Color empty = theme.brightness == Brightness.light
        ? const Color(0xFFF5F5F4)
        : const Color(0xFF2A221E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Row(
            children: List<Widget>.generate(24, (int h) {
              return Expanded(
                child: Text(
                  h % 3 == 0 ? '$h' : '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
              );
            }),
          ),
        ),
        for (int d = 0; d < rows.length; d++)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 34,
                  child: Text(_days[d], style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                ),
                ...List<Widget>.generate(24, (int h) {
                  final num value = rows[d][h];
                  final double t = max == 0 || value == 0
                      ? 0
                      : (value / max).clamp(0.12, 1).toDouble();
                  final bool picked = _day == d && _hour == h;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (picked) {
                          _day = null;
                          _hour = null;
                        } else {
                          _day = d;
                          _hour = h;
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: value == 0
                                  ? empty
                                  : AnalyticsPalette.primarySeries.withValues(alpha: t),
                              borderRadius: BorderRadius.circular(3),
                              border: picked
                                  ? Border.all(color: theme.colorScheme.onSurface, width: 1.4)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        if (_day != null && _hour != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '${_days[_day!]} ${_hour!}:00 — ${rows[_day!][_hour!]} events',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const SizedBox(width: 36),
            Text('Less', style: theme.textTheme.labelSmall),
            const SizedBox(width: 6),
            for (final double alpha in <double>[0.15, 0.35, 0.55, 0.8, 1])
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: AnalyticsPalette.primarySeries.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            Text('More', style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  static List<List<num>> _padded(List<List<num>> grid) {
    return List<List<num>>.generate(7, (int day) {
      final List<num> source = day < grid.length ? grid[day] : const <num>[];
      return List<num>.generate(24, (int hour) {
        return hour < source.length ? source[hour] : 0;
      });
    });
  }
}

class AnalyticsCriteriaList extends StatelessWidget {
  const AnalyticsCriteriaList({super.key, required this.entries});

  final List<CriteriaChangeEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'No criteria changes recorded yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      children: entries.map((CriteriaChangeEntry entry) {
        final Color dot = switch (entry.action) {
          'added' => AnalyticsPalette.success,
          'removed' => AnalyticsPalette.danger,
          _ => AnalyticsPalette.primarySeries,
        };
        final bool structured =
            entry.action != null && (entry.value != null || entry.fieldLabel != null);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      structured ? _structured(entry) : entry.change,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (entry.date.isNotEmpty)
                      Text(
                        entry.date,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _structured(CriteriaChangeEntry entry) {
    final String label = entry.displayLabel;
    if (entry.action == 'changed' && (entry.previous ?? '').isNotEmpty) {
      return '$label ${entry.actionVerb} from ${entry.previous} to ${entry.value ?? '—'}';
    }
    if ((entry.value ?? '').isNotEmpty) {
      return '$label ${entry.actionVerb} ${entry.value}';
    }
    return '$label ${entry.actionVerb}';
  }
}
