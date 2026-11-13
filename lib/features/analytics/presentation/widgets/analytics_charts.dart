import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/analytics_models.dart';

const Duration _kStill = Duration.zero;
const Color _axis = Color(0xFF94A3B8);
const Color _grid = Color(0x2264748B);

class SearchActivityChart extends StatelessWidget {
  const SearchActivityChart({super.key, required this.points});

  final List<SearchActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const _EmptyChart('No searches in this window yet.');
    final double maxY = points.fold<double>(1, (double max, SearchActivityPoint p) {
      final double local = math.max(p.searches.toDouble(), p.zeroResults.toDouble());
      return local > max ? local : max;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Legend(<(Color, String)>[
          (AnalyticsPalette.primarySeries, 'Searches'),
          (AnalyticsPalette.danger, 'Zero-result'),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.2,
              gridData: _gridData(),
              borderData: FlBorderData(show: false),
              lineTouchData: _lineTouch((List<LineBarSpot> spots) {
                return spots.map((LineBarSpot spot) {
                  final int i = spot.spotIndex;
                  if (i < 0 || i >= points.length) return null;
                  final SearchActivityPoint point = points[i];
                  if (spot.barIndex == 0) {
                    return LineTooltipItem(
                      '${point.month}\nSearches ${point.searches}',
                      _tipStyle,
                    );
                  }
                  return LineTooltipItem(
                    'Zero-result ${point.zeroResults}',
                    _tipStyle.copyWith(color: const Color(0xFFFCA5A5)),
                  );
                }).toList();
              }),
              titlesData: _titles(
                bottom: (double value, TitleMeta _) => _tick(
                  value,
                  points.length,
                  (int i) => points[i].month,
                ),
                leftInterval: _interval(maxY),
              ),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: <FlSpot>[
                    for (int i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].searches.toDouble()),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AnalyticsPalette.primarySeries,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AnalyticsPalette.primarySeries.withValues(alpha: 0.18),
                  ),
                ),
                LineChartBarData(
                  spots: <FlSpot>[
                    for (int i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].zeroResults.toDouble()),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AnalyticsPalette.danger,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (FlSpot _, double _, LineChartBarData _, int _) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: AnalyticsPalette.danger,
                        strokeWidth: 0,
                      );
                    },
                  ),
                ),
              ],
            ),
            duration: _kStill,
          ),
        ),
      ],
    );
  }
}

class LocationDonutChart extends StatelessWidget {
  const LocationDonutChart({super.key, required this.slices});

  final List<LocationSlice> slices;

  @override
  Widget build(BuildContext context) {
    final num total = slices.fold<num>(0, (num a, LocationSlice b) => a + b.count);
    if (slices.isEmpty || total == 0) {
      return const _EmptyChart('No location activity recorded yet.');
    }
    return _Donut(
      values: <double>[for (final LocationSlice slice in slices) slice.value.toDouble()],
      colors: <Color>[
        for (int i = 0; i < slices.length; i++) AnalyticsPalette.at(i),
      ],
      labels: <String>[for (final LocationSlice slice in slices) _short(slice.name, 18)],
      centerValue: '$total',
      centerCaption: 'listings',
      details: <String>[
        for (final LocationSlice slice in slices) '${slice.value}% · ${slice.count} listings',
      ],
    );
  }
}

class ShowingStatusDonut extends StatelessWidget {
  const ShowingStatusDonut({super.key, required this.rows});

  final List<NamedCount> rows;

  @override
  Widget build(BuildContext context) {
    final num total = rows.fold<num>(0, (num a, NamedCount b) => a + b.value);
    if (total == 0) {
      return const _EmptyChart('No showing requests in this window.');
    }
    return _Donut(
      values: <double>[for (final NamedCount row in rows) row.value.toDouble()],
      colors: <Color>[for (int i = 0; i < rows.length; i++) chartHex(rows[i].color, i)],
      labels: <String>[for (final NamedCount row in rows) row.name],
      centerValue: '$total',
      centerCaption: 'requests',
      details: <String>[
        for (final NamedCount row in rows) '${row.value} requests',
      ],
    );
  }
}

class ImportanceRadarChart extends StatelessWidget {
  const ImportanceRadarChart({super.key, required this.rows});

  final List<CriteriaUncertainty> rows;

  @override
  Widget build(BuildContext context) {
    final List<CriteriaUncertainty> top = <CriteriaUncertainty>[...rows]
      ..sort((CriteriaUncertainty a, CriteriaUncertainty b) {
        return b.currentImportance.compareTo(a.currentImportance);
      });
    final List<CriteriaUncertainty> shown = top.take(6).toList();
    final bool hasAny = shown.any((CriteriaUncertainty d) => d.currentImportance > 0);
    if (!hasAny || shown.length < 3) {
      if (!hasAny) return const _EmptyChart('Not enough criteria data yet.');
      return _VerticalBars(
        labels: <String>[for (final CriteriaUncertainty d in shown) d.criteria],
        values: <double>[
          for (final CriteriaUncertainty d in shown) d.currentImportance.toDouble(),
        ],
        colors: <Color>[
          for (int i = 0; i < shown.length; i++) AnalyticsPalette.at(i),
        ],
        maxY: 5,
      );
    }
    final Color border = Theme.of(context).dividerColor.withValues(alpha: 0.5);
    return SizedBox(
      height: 260,
      child: RadarChart(
        RadarChartData(
          tickCount: 5,
          titlePositionPercentageOffset: 0.15,
          radarShape: RadarShape.polygon,
          radarBorderData: BorderSide(color: border),
          gridBorderData: BorderSide(color: border),
          tickBorderData: const BorderSide(color: Colors.transparent),
          ticksTextStyle: const TextStyle(fontSize: 9, color: _axis),
          titleTextStyle: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          radarTouchData: RadarTouchData(enabled: false),
          getTitle: (int index, double _) {
            return RadarChartTitle(text: _short(shown[index].criteria, 14));
          },
          dataSets: <RadarDataSet>[
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
              entryRadius: 0,
              dataEntries: <RadarEntry>[
                for (int i = 0; i < shown.length; i++) const RadarEntry(value: 5),
              ],
            ),
            RadarDataSet(
              fillColor: AnalyticsPalette.primarySeries.withValues(alpha: 0.35),
              borderColor: AnalyticsPalette.primarySeries,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: <RadarEntry>[
                for (final CriteriaUncertainty d in shown)
                  RadarEntry(value: d.currentImportance.toDouble().clamp(0, 5)),
              ],
            ),
          ],
        ),
        duration: _kStill,
      ),
    );
  }
}

class UncertaintyBubbleChart extends StatelessWidget {
  const UncertaintyBubbleChart({super.key, required this.rows});

  final List<CriteriaUncertainty> rows;

  @override
  Widget build(BuildContext context) {
    final List<CriteriaUncertainty> shown = <CriteriaUncertainty>[
      for (final CriteriaUncertainty row in rows)
        if (row.totalChanges >= 2) row,
    ]..sort((CriteriaUncertainty a, CriteriaUncertainty b) {
        return a.totalChanges.compareTo(b.totalChanges);
      });
    if (shown.isEmpty) {
      return const _EmptyChart(
        'No repeated criteria changes yet. This fills in once a client revises the same criterion more than once.',
      );
    }
    final double maxX = shown.fold<double>(1, (double m, CriteriaUncertainty r) {
      return r.totalChanges.toDouble() > m ? r.totalChanges.toDouble() : m;
    });
    return SizedBox(
      height: 240,
      child: ScatterChart(
        ScatterChartData(
          minX: 0,
          maxX: maxX + 1,
          minY: 0,
          maxY: shown.length + 1,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          scatterTouchData: ScatterTouchData(
            touchTooltipData: ScatterTouchTooltipData(
              getTooltipColor: (ScatterSpot _) => _tipBg,
              getTooltipItems: (ScatterSpot spot) {
                final int i = spot.y.toInt() - 1;
                if (i < 0 || i >= shown.length) return null;
                final CriteriaUncertainty row = shown[i];
                return ScatterTooltipItem(
                  '${row.criteria}\n${row.totalChanges} changes',
                  textStyle: _tipStyle,
                );
              },
            ),
          ),
          titlesData: _titles(
            bottom: (double value, TitleMeta _) {
              if (value != value.roundToDouble()) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10, color: _axis),
                ),
              );
            },
            leftReserved: 78,
            left: (double value, TitleMeta _) {
              final int i = value.toInt() - 1;
              if (value != value.roundToDouble() || i < 0 || i >= shown.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _short(shown[i].criteria, 12),
                  style: const TextStyle(fontSize: 10, color: _axis),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          scatterSpots: <ScatterSpot>[
            for (int i = 0; i < shown.length; i++)
              ScatterSpot(
                shown[i].totalChanges.toDouble(),
                (i + 1).toDouble(),
                dotPainter: FlDotCirclePainter(
                  radius: 8 + (shown[i].totalChanges / maxX) * 8,
                  color: _bubbleColor(shown[i].totalChanges),
                ),
              ),
          ],
        ),
        duration: _kStill,
      ),
    );
  }
}

class UncertaintyBarChart extends StatelessWidget {
  const UncertaintyBarChart({super.key, required this.rows});

  final List<CriteriaUncertainty> rows;

  @override
  Widget build(BuildContext context) {
    final List<CriteriaUncertainty> shown = <CriteriaUncertainty>[
      for (final CriteriaUncertainty row in rows)
        if (row.totalChanges >= 2) row,
    ]..sort((CriteriaUncertainty a, CriteriaUncertainty b) {
        return b.totalChanges.compareTo(a.totalChanges);
      });
    if (shown.isEmpty) {
      return const _EmptyChart(
        'No repeated criteria changes yet. This fills in once a client revises the same criterion more than once.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Legend(<(Color, String)>[
          (AnalyticsPalette.primarySeries, 'Selection'),
          (AnalyticsPalette.warning, 'Importance'),
          (Color(0xFFEC4899), 'Flexibility'),
        ]),
        const SizedBox(height: 8),
        _VerticalBars(
          labels: <String>[for (final CriteriaUncertainty d in shown) d.criteria],
          values: <double>[
            for (final CriteriaUncertainty d in shown) math.max(d.totalChanges.toDouble(), 0),
          ],
          colors: const <Color>[],
          rods: <BarChartRodData>[
            for (final CriteriaUncertainty d in shown) _uncertaintyRod(d),
          ],
        ),
      ],
    );
  }
}

class ResultQualityChart extends StatelessWidget {
  const ResultQualityChart({super.key, required this.rows});

  final List<NamedCount> rows;

  @override
  Widget build(BuildContext context) {
    final num total = rows.fold<num>(0, (num a, NamedCount b) => a + b.value);
    if (total == 0) return const _EmptyChart('No searches recorded yet.');
    return _VerticalBars(
      labels: <String>[for (final NamedCount row in rows) row.name],
      values: <double>[for (final NamedCount row in rows) row.value.toDouble()],
      colors: <Color>[for (final NamedCount row in rows) _qualityColor(row.name)],
    );
  }
}

class ViewEngagementChart extends StatelessWidget {
  const ViewEngagementChart({super.key, required this.rows});

  final List<ViewEngagement> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _EmptyChart('Not enough engagement data yet.');
    final List<ViewEngagement> shown = <ViewEngagement>[...rows]
      ..sort((ViewEngagement a, ViewEngagement b) => b.avgSeconds.compareTo(a.avgSeconds));
    return _VerticalBars(
      labels: <String>[for (final ViewEngagement row in shown) row.type],
      values: <double>[for (final ViewEngagement row in shown) row.avgSeconds.toDouble()],
      colors: <Color>[
        for (int i = 0; i < shown.length; i++) AnalyticsPalette.primarySeries,
      ],
      valueLabel: _formatDuration,
    );
  }
}

class CriteriaDailyChart extends StatelessWidget {
  const CriteriaDailyChart({super.key, required this.points});

  final List<DailyCriteriaPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyChart('Not enough criteria history to draw a trend yet.');
    }
    final bool low = points.any((DailyCriteriaPoint p) => p.isLowActivity);
    final double dailyMax = points.fold<double>(1, (double max, DailyCriteriaPoint p) {
      return p.changes.toDouble() > max ? p.changes.toDouble() : max;
    });
    final double cumulativeMax = points.fold<double>(1, (double max, DailyCriteriaPoint p) {
      return p.cumulativeChanges.toDouble() > max ? p.cumulativeChanges.toDouble() : max;
    });
    Widget tick(double value, TitleMeta _) => _tick(
          value,
          points.length,
          (int i) => points[i].day.isEmpty ? points[i].date : points[i].day,
          stride: points.length > 8 ? 2 : 1,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Legend(<(Color, String)>[
          (AnalyticsPalette.primarySeries, 'Daily changes'),
          (AnalyticsPalette.success, 'Cumulative'),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
              minY: 0,
              maxY: dailyMax * 1.25,
              gridData: _gridData(),
              borderData: FlBorderData(show: false),
              lineTouchData: _lineTouch((List<LineBarSpot> spots) {
                return spots.map((LineBarSpot spot) {
                  final int i = spot.spotIndex;
                  if (i < 0 || i >= points.length) return null;
                  final DailyCriteriaPoint point = points[i];
                  final String day = point.day.isEmpty ? point.date : point.day;
                  return LineTooltipItem('$day\n${point.changes} changes', _tipStyle);
                }).toList();
              }),
              titlesData: _titles(bottom: tick, leftInterval: _interval(dailyMax)),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: <FlSpot>[
                    for (int i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].changes.toDouble()),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AnalyticsPalette.primarySeries,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AnalyticsPalette.primarySeries.withValues(alpha: 0.16),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (FlSpot _, double _, LineChartBarData _, int index) {
                      final bool alert = index < points.length && points[index].isLowActivity;
                      return FlDotCirclePainter(
                        radius: 3,
                        color: alert ? AnalyticsPalette.danger : AnalyticsPalette.primarySeries,
                        strokeWidth: 0,
                      );
                    },
                  ),
                ),
              ],
            ),
            duration: _kStill,
          ),
        ),
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
              minY: 0,
              maxY: math.max(cumulativeMax * 1.2, 10),
              gridData: _gridData(),
              borderData: FlBorderData(show: false),
              lineTouchData: _lineTouch((List<LineBarSpot> spots) {
                return spots.map((LineBarSpot spot) {
                  final int i = spot.spotIndex;
                  if (i < 0 || i >= points.length) return null;
                  final DailyCriteriaPoint point = points[i];
                  final String day = point.day.isEmpty ? point.date : point.day;
                  return LineTooltipItem(
                    '$day\nCumulative ${point.cumulativeChanges}',
                    _tipStyle.copyWith(color: const Color(0xFF6EE7B7)),
                  );
                }).toList();
              }),
              extraLinesData: ExtraLinesData(
                horizontalLines: <HorizontalLine>[
                  HorizontalLine(
                    y: 10,
                    color: AnalyticsPalette.warning,
                    strokeWidth: 1,
                    dashArray: <int>[4, 4],
                  ),
                ],
              ),
              titlesData: _titles(
                bottom: (double _, TitleMeta _) => const SizedBox.shrink(),
                bottomReserved: 8,
                leftInterval: _interval(cumulativeMax),
              ),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: <FlSpot>[
                    for (int i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].cumulativeChanges.toDouble()),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AnalyticsPalette.success,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
            duration: _kStill,
          ),
        ),
        if (low) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Alert: after the first 4 weeks, cumulative criteria changes are still under 10 on one or more days.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFDC2626),
                ),
          ),
        ],
      ],
    );
  }
}

class EngagementBreakdown extends StatelessWidget {
  const EngagementBreakdown({super.key, required this.stages});

  final List<FunnelStage> stages;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasAny = stages.any((FunnelStage s) => s.value > 0);
    if (!hasAny) return const _EmptyChart('No engagement recorded yet.');
    final num searches = _stage(RegExp('search', caseSensitive: false));
    final num viewed = _stage(RegExp('view', caseSensitive: false));
    final num favorited = _stage(RegExp('favorit|saved', caseSensitive: false));
    final num showings = _stage(RegExp('showing|tour', caseSensitive: false));
    final int? intent = _rate(showings, viewed);
    final List<({String label, int? value})> rates = <({String label, int? value})>[
      (label: 'Search → View', value: _rate(viewed, searches)),
      (label: 'View → Save', value: _rate(favorited, viewed)),
      (label: 'View → Showing', value: intent),
    ];
    return Column(
      children: <Widget>[
        _SpeedGauge(
          value: intent,
          needle: theme.colorScheme.onSurface,
          track: theme.brightness == Brightness.light
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF3A2E28),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _stageColor(stages[i].stage, i).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _stageIcon(stages[i].stage),
                    size: 15,
                    color: _stageColor(stages[i].stage, i),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stages[i].stage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${stages[i].value}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            for (int i = 0; i < rates.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _RateChip(label: rates[i].label, value: rates[i].value)),
            ],
          ],
        ),
      ],
    );
  }

  num _stage(RegExp pattern) {
    for (final FunnelStage stage in stages) {
      if (pattern.hasMatch(stage.stage)) return stage.value;
    }
    return 0;
  }
}

class _SpeedGauge extends StatelessWidget {
  const _SpeedGauge({
    required this.value,
    required this.needle,
    required this.track,
  });

  final int? value;
  final Color needle;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final double pct = (value ?? 0).clamp(0, 100).toDouble();
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 132,
          width: double.infinity,
          child: ClipRect(
            child: CustomPaint(
              painter: _GaugePainter(pct: pct, needle: needle, track: track),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value == null ? '—' : '${pct.round()}%',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'VIEW → SHOWING',
          style: theme.textTheme.labelSmall?.copyWith(
            color: _axis,
            letterSpacing: 0.4,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.pct, required this.needle, required this.track});

  final double pct;
  final Color needle;
  final Color track;

  /// 0 is the left end of the arch and 100 is the right end.
  /// Flutter measures angles clockwise from the right, so the top is 3π/2.
  Offset _point(Offset center, double radius, double percent) {
    final double angle = math.pi * (1 + percent / 100);
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  void _arch(Canvas canvas, Rect oval, double from, double to, Paint paint) {
    canvas.drawArc(
      oval,
      math.pi * (1 + from / 100),
      math.pi * ((to - from) / 100),
      false,
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 16;
    final double radius = math.min(size.width / 2 - 28, size.height - stroke - 12);
    final Offset center = Offset(size.width / 2, radius + stroke / 2 + 4);
    final Rect oval = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    paint.color = track;
    _arch(canvas, oval, 0, 100, paint);
    paint.strokeCap = StrokeCap.butt;
    const List<(double, double, Color)> zones = <(double, double, Color)>[
      (0, 33, Color(0xFFEF4444)),
      (33, 66, Color(0xFFF59E0B)),
      (66, 100, Color(0xFF10B981)),
    ];
    for (final (double, double, Color) zone in zones) {
      paint.color = zone.$3.withValues(alpha: 0.9);
      _arch(canvas, oval, zone.$1, zone.$2, paint);
    }
    final Offset tip = _point(center, radius - 2, pct);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = needle
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 6, Paint()..color = needle);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.pct != pct || oldDelegate.needle != needle || oldDelegate.track != track;
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value == null ? '—' : '$value%',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _VerticalBars extends StatelessWidget {
  const _VerticalBars({
    required this.labels,
    required this.values,
    required this.colors,
    this.rods,
    this.maxY,
    this.valueLabel,
  });

  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final List<BarChartRodData>? rods;
  final double? maxY;
  final String Function(double value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    double peak = values.fold<double>(1, (double m, double v) => v > m ? v : m);
    if (rods != null) {
      for (final BarChartRodData rod in rods!) {
        if (rod.toY > peak) peak = rod.toY;
      }
    }
    final double top = maxY ?? peak * 1.2;
    return SizedBox(
      height: 230,
      child: BarChart(
        BarChartData(
          maxY: top,
          minY: 0,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          barTouchData: _barTouch(labels, values, valueLabel),
          alignment: BarChartAlignment.spaceAround,
          titlesData: _titles(
            leftInterval: _interval(top),
            bottomReserved: 42,
            bottom: (double value, TitleMeta _) {
              final int i = value.toInt();
              if (i < 0 || i >= labels.length || value != i.toDouble()) {
                return const SizedBox.shrink();
              }
              final String extra = valueLabel == null ? '' : '\n${valueLabel!(values[i])}';
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_short(labels[i], 10)}$extra',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: _axis, height: 1.15),
                ),
              );
            },
          ),
          barGroups: <BarChartGroupData>[
            for (int i = 0; i < labels.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  rods != null
                      ? rods![i]
                      : BarChartRodData(
                          toY: values[i],
                          color: colors[i],
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                ],
              ),
          ],
        ),
        duration: _kStill,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.items);

  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: <Widget>[
        for (final (Color, String) item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: item.$1, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(item.$2, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

FlGridData _gridData() {
  return FlGridData(
    show: true,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (double _) => const FlLine(color: _grid, strokeWidth: 1),
  );
}

FlTitlesData _titles({
  required Widget Function(double, TitleMeta) bottom,
  Widget Function(double, TitleMeta)? left,
  double leftInterval = 1,
  double bottomReserved = 28,
  double leftReserved = 32,
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: leftReserved,
        interval: leftInterval,
        getTitlesWidget: left ??
            (double value, TitleMeta _) {
              if (value < 0) return const SizedBox.shrink();
              final String text = value == value.roundToDouble()
                  ? '${value.toInt()}'
                  : value.toStringAsFixed(0);
              return Text(text, style: const TextStyle(fontSize: 10, color: _axis));
            },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: bottomReserved,
        interval: 1,
        getTitlesWidget: bottom,
      ),
    ),
  );
}

Widget _tick(double value, int length, String Function(int) label, {int stride = 1}) {
  final int i = value.round();
  if ((value - i).abs() > 0.01 || i < 0 || i >= length) return const SizedBox.shrink();
  if (i % stride != 0 && i != length - 1) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(_short(label(i), 8), style: const TextStyle(fontSize: 10, color: _axis)),
  );
}

double _interval(double max) {
  if (max <= 5) return 1;
  if (max <= 12) return 2;
  if (max <= 40) return 10;
  return (max / 4).ceilToDouble();
}

String _short(String name, [int max = 18]) {
  final String trimmed = name.trim();
  if (trimmed.length <= max) return trimmed;
  return '${trimmed.substring(0, max - 1)}…';
}

int? _rate(num numerator, num denominator) {
  if (denominator == 0) return null;
  return ((numerator / denominator) * 100).round();
}

Color chartHex(String? hex, int index) {
  if (hex == null || hex.isEmpty) return AnalyticsPalette.at(index);
  final String raw = hex.replaceFirst('#', '');
  if (raw.length != 6) return AnalyticsPalette.at(index);
  final int? parsed = int.tryParse('FF$raw', radix: 16);
  return parsed == null ? AnalyticsPalette.at(index) : Color(parsed);
}

BarChartRodData _uncertaintyRod(CriteriaUncertainty row) {
  final double selection = row.selectionChanges.toDouble();
  final double importance = row.importanceChanges.toDouble();
  final double flexibility = row.flexibilityChanges.toDouble();
  final double stacked = selection + importance + flexibility;
  if (stacked <= 0) {
    return BarChartRodData(
      toY: row.totalChanges.toDouble(),
      width: 16,
      color: AnalyticsPalette.primarySeries,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    );
  }
  return BarChartRodData(
    toY: stacked,
    width: 16,
    color: AnalyticsPalette.primarySeries,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    rodStackItems: <BarChartRodStackItem>[
      BarChartRodStackItem(0, selection, AnalyticsPalette.primarySeries),
      BarChartRodStackItem(selection, selection + importance, AnalyticsPalette.warning),
      BarChartRodStackItem(
        selection + importance,
        stacked,
        const Color(0xFFEC4899),
      ),
    ],
  );
}

Color _bubbleColor(num changes) {
  if (changes > 5) return AnalyticsPalette.danger;
  if (changes >= 3) return AnalyticsPalette.warning;
  return const Color(0xFF22C55E);
}

Color _qualityColor(String name) {
  final String key = name.replaceAll('-', '–').trim();
  return switch (key) {
    '0' => AnalyticsPalette.danger,
    '1–5' => AnalyticsPalette.warning,
    '6–20' => AnalyticsPalette.success,
    '21–50' => AnalyticsPalette.primarySeries,
    '51+' => AnalyticsPalette.neutral,
    _ => AnalyticsPalette.primarySeries,
  };
}

IconData _stageIcon(String stage) {
  final String value = stage.toLowerCase();
  if (value.contains('search')) return Icons.search;
  if (value.contains('view')) return Icons.visibility_outlined;
  if (value.contains('favorit') || value.contains('saved')) return Icons.favorite_border;
  if (value.contains('compar')) return Icons.compare_arrows;
  if (value.contains('showing') || value.contains('tour')) return Icons.event_available_outlined;
  return Icons.insights_outlined;
}

Color _stageColor(String stage, int index) {
  final String value = stage.toLowerCase();
  if (value.contains('search')) return const Color(0xFF6366F1);
  if (value.contains('view')) return const Color(0xFF8B5CF6);
  if (value.contains('favorit') || value.contains('saved')) return const Color(0xFFEC4899);
  if (value.contains('compar')) return const Color(0xFFF59E0B);
  if (value.contains('showing') || value.contains('tour')) return const Color(0xFF10B981);
  return AnalyticsPalette.at(index);
}

String _formatDuration(double seconds) {
  final int s = seconds.round();
  if (s < 60) return '${s}s';
  final int m = s ~/ 60;
  final int rem = s % 60;
  return rem == 0 ? '${m}m' : '${m}m ${rem}s';
}

const TextStyle _tipStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w600,
  fontSize: 12,
  height: 1.3,
);
const Color _tipBg = Color(0xFF1F1206);

LineTouchData _lineTouch(List<LineTooltipItem?> Function(List<LineBarSpot>) items) {
  return LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      tooltipBorderRadius: BorderRadius.circular(10),
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      maxContentWidth: 180,
      getTooltipColor: (LineBarSpot _) => _tipBg,
      getTooltipItems: items,
    ),
  );
}

BarTouchData _barTouch(
  List<String> labels,
  List<double> values,
  String Function(double value)? format,
) {
  return BarTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: BarTouchTooltipData(
      tooltipBorderRadius: BorderRadius.circular(10),
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipColor: (BarChartGroupData _) => _tipBg,
      getTooltipItem: (
        BarChartGroupData group,
        int groupIndex,
        BarChartRodData rod,
        int rodIndex,
      ) {
        final int i = group.x;
        if (i < 0 || i >= labels.length) return null;
        final String value = format == null ? _compactNumber(values[i]) : format(values[i]);
        return BarTooltipItem('${labels[i]}\n$value', _tipStyle);
      },
    ),
  );
}

String _compactNumber(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(1);
}

class _Donut extends StatefulWidget {
  const _Donut({
    required this.values,
    required this.colors,
    required this.labels,
    required this.centerValue,
    required this.centerCaption,
    required this.details,
  });

  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final String centerValue;
  final String centerCaption;
  final List<String> details;

  @override
  State<_Donut> createState() => _DonutState();
}

class _DonutState extends State<_Donut> {
  int _touched = -1;

  void _select(int index) {
    if (!mounted) return;
    setState(() => _touched = _touched == index ? -1 : index);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool selected = _touched >= 0 && _touched < widget.labels.length;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PieChart(
                PieChartData(
                  centerSpaceRadius: 58,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                      if (event is! FlTapUpEvent) return;
                      final int index = response?.touchedSection?.touchedSectionIndex ?? -1;
                      if (index < 0) return;
                      _select(index);
                    },
                  ),
                  sections: <PieChartSectionData>[
                    for (int i = 0; i < widget.values.length; i++)
                      PieChartSectionData(
                        value: math.max(widget.values[i], 0.01),
                        color: widget.colors[i],
                        radius: i == _touched ? 50 : 34,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 180),
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        selected ? widget.labels[_touched] : widget.centerValue,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        selected ? widget.details[_touched] : widget.centerCaption,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(color: _axis),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (int i = 0; i < widget.labels.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => _select(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == _touched
                        ? widget.colors[i].withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: widget.colors[i], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.labels[i]} ${widget.details[i]}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: i == _touched ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
