import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/models/analytics_models.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/analytics_sections.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AnalyticsViewData> async =
        ref.watch(analyticsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: DashboardAppBarActions.of(
          extra: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              onPressed: () =>
                  ref.read(analyticsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(analyticsControllerProvider.notifier).refresh(),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: Text('Loading analytics…')),
          error: (Object error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text(
                'Failed to load analytics. Please try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString()),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(analyticsControllerProvider.notifier).refresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
          data: (AnalyticsViewData view) => _AnalyticsBody(view: view),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.view});

  final AnalyticsViewData view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Text(
          "Insights and trends for your clients' search activity",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('client-${view.selectedBuyerId}'),
          initialValue:
              view.clients.any((AnalyticsClient c) => c.id == view.selectedBuyerId)
                  ? view.selectedBuyerId
                  : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Client'),
          hint: const Text('Select a client'),
          items: view.clients
              .map(
                (AnalyticsClient c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.pickerLabel, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: view.clients.isEmpty
              ? null
              : (String? id) {
                  if (id != null) {
                    ref.read(analyticsControllerProvider.notifier).selectClient(id);
                  }
                },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          key: ValueKey<int>(view.months),
          initialValue: view.months,
          decoration: const InputDecoration(labelText: 'Range'),
          items: AnalyticsRange.values
              .map(
                (AnalyticsRange r) => DropdownMenuItem<int>(
                  value: r.months,
                  child: Text(r.label),
                ),
              )
              .toList(),
          onChanged: view.clients.isEmpty
              ? null
              : (int? months) {
                  if (months != null) {
                    ref.read(analyticsControllerProvider.notifier).setMonths(months);
                  }
                },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (view.overviewFailed)
          Text(
            'Failed to load analytics. Please try again.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else if (view.overview == null && view.clients.isEmpty)
          const SizedBox.shrink()
        else if (view.overview == null)
          const Text('Loading analytics…')
        else if (view.sharingDisabled)
          const _SharingDisabledAlert()
        else ...<Widget>[
          AnalyticsAiCard(view: view),
          const SizedBox(height: AppSpacing.md),
          AnalyticsStatGrid(stats: view.overview!.stats),
          const SizedBox(height: AppSpacing.md),
          ..._charts(view.overview!),
        ],
      ],
    );
  }

  List<Widget> _charts(AnalyticsOverview data) {
    return <Widget>[
      AnalyticsChartCard(
        title: 'Engagement funnel',
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (int i = 0; i < data.engagementFunnel.length; i++)
              (
                data.engagementFunnel[i].stage,
                data.engagementFunnel[i].value,
                AnalyticsPalette.at(i),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Criteria importance',
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (int i = 0; i < data.criteriaUncertainty.length; i++)
              (
                data.criteriaUncertainty[i].criteria,
                data.criteriaUncertainty[i].currentImportance,
                AnalyticsPalette.at(i),
              ),
          ],
        ),
      ),
      if (data.criteriaUncertainty.isNotEmpty) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        AnalyticsChartCard(
          title: 'Criteria uncertainty',
          child: AnalyticsBarList(
            rows: <(String, num, Color)>[
              for (int i = 0; i < data.criteriaUncertainty.length; i++)
                (
                  data.criteriaUncertainty[i].criteria,
                  data.criteriaUncertainty[i].totalChanges,
                  AnalyticsPalette.at(i),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Activity heatmap',
        child: AnalyticsHeatmap(grid: data.activityHeatmap),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Result quality',
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (int i = 0; i < data.resultQuality.length; i++)
              (
                data.resultQuality[i].name,
                data.resultQuality[i].value,
                AnalyticsPalette.at(i),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'View engagement',
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (int i = 0; i < data.viewEngagement.length; i++)
              (
                '${data.viewEngagement[i].type} · ${data.viewEngagement[i].avgSeconds}s',
                data.viewEngagement[i].views,
                AnalyticsPalette.at(i),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Showing status',
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (int i = 0; i < data.showingStatus.length; i++)
              (
                data.showingStatus[i].name,
                data.showingStatus[i].value,
                _hexOrPalette(data.showingStatus[i].color, i),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Criteria changes daily',
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (final DailyCriteriaPoint p in data.criteriaChangesDaily)
              (p.day.isEmpty ? p.date : p.day, p.changes, AnalyticsPalette.primarySeries),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Search Activity Over Time',
        subtitle: 'Searches per month with zero-result count overlay',
        insight: AnalyticsInsights.searchActivity(data.searchActivity),
        child: AnalyticsBarList(
          rows: <(String, num, Color)>[
            for (final SearchActivityPoint p in data.searchActivity)
              (p.month, p.searches, AnalyticsPalette.primarySeries),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Location Distribution',
        insight: AnalyticsInsights.location(data.locationDistribution),
        child: data.locationDistribution.isEmpty
            ? const Text('No location activity recorded yet.')
            : AnalyticsBarList(
                valueSuffix: '%',
                rows: <(String, num, Color)>[
                  for (int i = 0; i < data.locationDistribution.length; i++)
                    (
                      _truncate(data.locationDistribution[i].name),
                      data.locationDistribution[i].value,
                      AnalyticsPalette.at(i),
                    ),
                ],
              ),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Recent Criteria Changes',
        insight: AnalyticsInsights.recentChanges(data.recentCriteriaChanges),
        child: AnalyticsCriteriaList(entries: data.recentCriteriaChanges),
      ),
    ];
  }

  Color _hexOrPalette(String? hex, int index) {
    if (hex == null || hex.isEmpty) return AnalyticsPalette.at(index);
    final String raw = hex.replaceFirst('#', '');
    if (raw.length != 6) return AnalyticsPalette.at(index);
    return Color(int.parse('FF$raw', radix: 16));
  }

  String _truncate(String name) {
    if (name.length <= 22) return name;
    return '${name.substring(0, 21)}…';
  }
}

class _SharingDisabledAlert extends StatelessWidget {
  const _SharingDisabledAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.amberBanner,
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.shield_outlined),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: 'Sharing disabled. ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        "This client has turned off sharing of their search insights, so detailed analytics aren't available. You can still view their basic profile in the Clients section.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
