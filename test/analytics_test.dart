import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/analytics/domain/models/analytics_models.dart';
import 'package:mangoliving_agent/features/analytics/presentation/controllers/analytics_controller.dart';
import 'package:mangoliving_agent/features/analytics/presentation/pages/analytics_page.dart';

class _FakeAnalyticsController extends AnalyticsController {
  _FakeAnalyticsController(this.initial);

  final AnalyticsViewData initial;

  @override
  Future<AnalyticsViewData> build() async => initial;
}

AnalyticsOverview _overview({
  bool enabled = true,
  int searches = 42,
  List<SearchActivityPoint> activity = const <SearchActivityPoint>[],
  List<LocationSlice> locations = const <LocationSlice>[],
  List<CriteriaChangeEntry> changes = const <CriteriaChangeEntry>[],
}) {
  return AnalyticsOverview(
    analyticsEnabled: enabled,
    stats: AnalyticsStats(
      totalSearches: StatMetric(value: searches, deltaPct: 12, window: 'vs prior'),
      propertiesViewed: const StatMetric(value: 18),
      viewingRequests: const StatMetric(
        value: 3,
        pending: 1,
        scheduled: 1,
        completed: 1,
      ),
      zeroResultSearches: const StatMetric(
        value: 2,
        unit: '%',
        label: 'of searches',
        lifetime: 9,
      ),
      favorites: const StatMetric(value: 5),
      compared: const StatMetric(value: 4),
    ),
    searchActivity: activity,
    locationDistribution: locations,
    recentCriteriaChanges: changes,
    aiInsights: const <AiInsight>[
      AiInsight(tone: InsightTone.info, text: 'Buyer is focused on Frisco.'),
    ],
  );
}

void main() {
  test('client picker label marks sharing disabled', () {
    expect(
      const AnalyticsClient(
        id: '1',
        agentClientId: 'a1',
        name: 'Maya Chen',
        email: 'm@x.com',
        analyticsEnabled: false,
      ).pickerLabel,
      'Maya Chen (Sharing Disabled)',
    );
  });

  test('stat metric copy', () {
    const StatMetric requests = StatMetric(
      value: 3,
      pending: 1,
      scheduled: 2,
    );
    expect(requests.viewingRequestsDetail, '1 pending, 2 scheduled');
    expect(const StatMetric(value: 0).viewingRequestsDetail, 'No requests yet');
    expect(const StatMetric(value: 12, deltaPct: 12).deltaLabel, '↑ 12%');
    expect(const StatMetric(value: 12, deltaPct: -8).deltaLabel, '↓ 8%');
    expect(
      const StatMetric(value: 2, unit: '%', label: 'of searches', lifetime: 9)
          .zeroResultDetail,
      'of searches · lifetime 9%',
    );
  });

  test('search / location / recent insights', () {
    expect(
      AnalyticsInsights.searchActivity(const <SearchActivityPoint>[]).message,
      'No searches in this window yet.',
    );
    expect(
      AnalyticsInsights.searchActivity(const <SearchActivityPoint>[
        SearchActivityPoint(month: 'Jan', searches: 10, zeroResults: 4),
        SearchActivityPoint(month: 'Feb', searches: 10, zeroResults: 2),
      ]).tone,
      InsightTone.concern,
    );
    expect(
      AnalyticsInsights.location(const <LocationSlice>[
        LocationSlice(name: 'Frisco', value: 72, count: 20),
      ]).message,
      contains('Clearly focused on Frisco'),
    );
    expect(
      AnalyticsInsights.recentChanges(const <CriteriaChangeEntry>[]).message,
      contains('No recent criteria churn'),
    );
  });

  testWidgets('Analytics shows picker, AI, stats, and privacy gate', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          analyticsControllerProvider.overrideWith(
            () => _FakeAnalyticsController(
              AnalyticsViewData(
                clients: const <AnalyticsClient>[
                  AnalyticsClient(
                    id: 'b1',
                    agentClientId: 'ac1',
                    name: 'Maya Chen',
                    email: 'maya@example.com',
                  ),
                ],
                months: 6,
                selectedBuyerId: 'b1',
                overview: _overview(
                  activity: const <SearchActivityPoint>[
                    SearchActivityPoint(month: 'Aug', searches: 8, zeroResults: 1),
                  ],
                  locations: const <LocationSlice>[
                    LocationSlice(name: 'Frisco', value: 70, count: 12),
                  ],
                ),
                ai: const AiSummary(
                  summary: 'Maya is actively searching in Frisco.',
                  highlights: <AiInsight>[
                    AiInsight(tone: InsightTone.info, text: 'Strong Frisco focus.'),
                  ],
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("Insights and trends for your clients' search activity"),
      findsOneWidget,
    );
    expect(find.text('Last 6 months'), findsOneWidget);
    expect(find.text('AI-Powered Insights'), findsOneWidget);
    expect(find.text('Maya is actively searching in Frisco.'), findsOneWidget);
    expect(find.text('Total Searches'), findsOneWidget);
    expect(find.text('1 pending, 1 scheduled, 1 completed'), findsOneWidget);
    expect(find.text('Search Activity Over Time'), findsOneWidget);
    expect(find.text('Location Distribution'), findsOneWidget);
    expect(find.text('Sharing disabled.'), findsNothing);
  });

  testWidgets('sharing disabled hides charts and AI', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          analyticsControllerProvider.overrideWith(
            () => _FakeAnalyticsController(
              AnalyticsViewData(
                clients: const <AnalyticsClient>[
                  AnalyticsClient(
                    id: 'b1',
                    agentClientId: 'ac1',
                    name: 'Maya Chen',
                    email: 'm@x.com',
                    analyticsEnabled: false,
                  ),
                ],
                months: 6,
                selectedBuyerId: 'b1',
                overview: _overview(enabled: false),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sharing disabled.'), findsOneWidget);
    expect(find.text('AI-Powered Insights'), findsNothing);
    expect(find.text('Total Searches'), findsNothing);
    expect(find.text('Maya Chen (Sharing Disabled)'), findsOneWidget);
  });
}
