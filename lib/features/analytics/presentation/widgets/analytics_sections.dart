import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.05),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'AI-Powered Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (view.aiLoading)
            Row(
              children: <Widget>[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Generating AI summary…',
                  style: theme.textTheme.bodySmall,
                ),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: <Widget>[
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
    final String? delta = metric.deltaLabel;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            valueOverride ?? '${metric.value}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (delta != null)
            Text(
              '$delta ${metric.window ?? ''}'.trim(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: metric.deltaUp ? AnalyticsPalette.success : AnalyticsPalette.danger,
              ),
            )
          else if ((detail ?? metric.window ?? '').isNotEmpty)
            Text(
              detail ?? metric.window ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
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
            Text(title, style: theme.textTheme.titleMedium),
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

class AnalyticsBarList extends StatelessWidget {
  const AnalyticsBarList({
    super.key,
    required this.rows,
    this.empty,
    this.valueSuffix = '',
  });

  final List<(String, num, Color)> rows;
  final String? empty;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        empty ?? 'No data yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final num max = rows.fold<num>(0, (num a, (String, num, Color) b) {
      return b.$2 > a ? b.$2 : a;
    });
    return Column(
      children: rows.map(((String, num, Color) row) {
        final double fraction = max == 0 ? 0 : (row.$2 / max).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      row.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${row.$2}$valueSuffix'),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  color: row.$3,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class AnalyticsHeatmap extends StatelessWidget {
  const AnalyticsHeatmap({super.key, required this.grid});

  final List<List<num>> grid;

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
    if (grid.isEmpty) {
      return Text(
        'No activity heatmap yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    num max = 0;
    for (final List<num> row in grid) {
      for (final num cell in row) {
        if (cell > max) max = cell;
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int d = 0; d < grid.length && d < 7; d++)
            Row(
              children: <Widget>[
                SizedBox(
                  width: 36,
                  child: Text(_days[d], style: Theme.of(context).textTheme.labelSmall),
                ),
                ...List<Widget>.generate(grid[d].length.clamp(0, 24), (int h) {
                  final num value = grid[d][h];
                  final double t = max == 0 ? 0 : (value / max).toDouble();
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: AnalyticsPalette.primarySeries.withValues(
                        alpha: 0.12 + (t * 0.88),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
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
