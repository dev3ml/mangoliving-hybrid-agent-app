import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/models/analytics_models.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/analytics_charts.dart';
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
        actions: DashboardAppBarActions.of(),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(analyticsControllerProvider.notifier).refresh(),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const AppSkeletonPage(),
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
                color: AppColors.muted,
                height: 1.35,
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
          const AppSkeletonPage(count: 3, shrinkWrap: true)
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
        title: 'Engagement Breakdown',
        subtitle: 'How this client moves from browsing to taking action',
        child: EngagementBreakdown(stages: data.engagementFunnel),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Importance Profile',
        subtitle: "Current importance (1–5) for the buyer's top criteria",
        child: ImportanceRadarChart(rows: data.criteriaUncertainty),
      ),
      if (data.criteriaUncertainty.isNotEmpty) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        AnalyticsChartCard(
          title: 'Client Uncertainty per Criteria',
          subtitle: 'Each criterion the client revisited — bubble size shows how often it changed',
          child: UncertaintyBubbleChart(rows: data.criteriaUncertainty),
        ),
        const SizedBox(height: AppSpacing.md),
        AnalyticsChartCard(
          title: 'Criteria Uncertainty Overview',
          subtitle: 'Selection, importance, and flexibility adjustments per criteria',
          child: UncertaintyBarChart(rows: data.criteriaUncertainty),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Activity Heatmap',
        subtitle: 'When this buyer is active — best hours to follow up',
        child: AnalyticsHeatmap(grid: data.activityHeatmap),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Search Result Quality',
        subtitle: 'How many results each search returned — too narrow vs too broad',
        child: ResultQualityChart(rows: data.resultQuality),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Average Engagement Time',
        subtitle: 'Mean time on listing page per property type',
        child: ViewEngagementChart(rows: data.viewEngagement),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Showing Request Status',
        subtitle: 'Outcome breakdown for tour requests routed through you',
        child: ShowingStatusDonut(rows: data.showingStatus),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Criteria Changes Over Days',
        subtitle:
            'Daily criteria revisions with cumulative trend. Red markers indicate less than 10 total changes after week 4.',
        child: CriteriaDailyChart(points: data.criteriaChangesDaily),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Search Activity Over Time',
        subtitle: 'Searches per month with zero-result count overlay',
        insight: AnalyticsInsights.searchActivity(data.searchActivity),
        child: SearchActivityChart(points: data.searchActivity),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Location Distribution',
        insight: AnalyticsInsights.location(data.locationDistribution),
        child: LocationDonutChart(slices: data.locationDistribution),
      ),
      const SizedBox(height: AppSpacing.md),
      AnalyticsChartCard(
        title: 'Recent Criteria Changes',
        insight: AnalyticsInsights.recentChanges(data.recentCriteriaChanges),
        child: AnalyticsCriteriaList(entries: data.recentCriteriaChanges),
      ),
    ];
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
