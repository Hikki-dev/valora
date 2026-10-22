import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency_provider.dart';
import '../../../core/tokens.dart';
import '../../../models/game.dart';
import '../../../widgets/comic.dart';

enum _Range {
  m1('1M', 30),
  m3('3M', 90),
  y1('1Y', 365),
  all('All', null);

  final String label;
  final int? days;
  const _Range(this.label, this.days);
}

class _Point {
  final DateTime at;
  final double price;
  const _Point(this.at, this.price);
}

/// Value history for the copy the user owns, with 1M / 3M / 1Y / All ranges.
class HistoricalPriceChart extends ConsumerStatefulWidget {
  final Game game;
  final List<Map<String, dynamic>> history;

  const HistoricalPriceChart({
    super.key,
    required this.game,
    required this.history,
  });

  @override
  ConsumerState<HistoricalPriceChart> createState() =>
      _HistoricalPriceChartState();
}

class _HistoricalPriceChartState extends ConsumerState<HistoricalPriceChart> {
  _Range _range = _Range.all;

  String get _column {
    final g = widget.game;
    if (g.platform.isDigital) return 'price_digital';
    switch (g.condition) {
      case GameCondition.loose:
        return 'price_loose';
      case GameCondition.cib:
      case GameCondition.boxed:
        return 'price_complete';
      case GameCondition.new_:
        return 'price_new';
    }
  }

  List<_Point> _points() {
    final col = _column;
    final out = <_Point>[];
    for (final row in widget.history) {
      final price = (row[col] as num?)?.toDouble();
      final at = DateTime.tryParse('${row['fetched_at']}');
      if (price == null || price <= 0 || at == null) continue;
      out.add(_Point(at.toLocal(), price));
    }
    final days = _range.days;
    if (days == null) return out;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return out.where((p) => p.at.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final pts = _points();

    Widget body;
    if (widget.history.isEmpty) {
      body = const _Note(
          text:
              'History starts building after the first price check. Come back in a few days.');
    } else if (pts.isEmpty) {
      body = const _Note(text: 'No price recorded in this range. Try a longer one.');
    } else if (pts.length == 1) {
      body = _Note(
          text: 'Only one price so far: ${currency.format(pts.first.price)}. '
              'A line appears once there are two or more.');
    } else {
      body = _Chart(
        points: pts,
        purchase: widget.game.purchasePrice,
        currency: currency,
      );
    }

    final prices = pts.map((p) => p.price);
    final hi = prices.isEmpty ? null : prices.reduce((a, b) => a > b ? a : b);
    final lo = prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);

    return HardBox(
      padding: const EdgeInsets.all(16),
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('VALUE HISTORY', style: VText.label(12, t.muted)),
              const Spacer(),
              for (final r in _Range.values) ...[
                const SizedBox(width: 6),
                _RangeChip(
                  label: r.label,
                  selected: r == _range,
                  onTap: () => setState(() => _range = r),
                ),
              ],
            ],
          ),
          if (hi != null && lo != null && pts.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'HIGH', value: currency.format(hi), color: t.text),
                const SizedBox(width: 24),
                _Stat(label: 'LOW', value: currency.format(lo), color: t.text),
              ],
            ),
          ],
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
                key: ValueKey('${_range.name}-${pts.length}'), child: body),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Show $label',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 36),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? t.money : Colors.transparent,
                border: Border.all(
                    color: selected ? t.line : t.soft, width: 2),
              ),
              child: Text(label,
                  style: VText.body(12, selected ? t.onMoney : t.muted,
                      weight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VText.label(11, t.muted)),
        const SizedBox(height: 2),
        Text(value, style: VText.display(16, color)),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      height: 110,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text,
          textAlign: TextAlign.center,
          style: VText.body(13, t.muted, weight: FontWeight.w500)),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart(
      {required this.points, required this.purchase, required this.currency});
  final List<_Point> points;
  final double? purchase;
  final CurrencyState currency;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].price)
    ];
    var minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    var maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (purchase != null) {
      if (purchase! < minY) minY = purchase!;
      if (purchase! > maxY) maxY = purchase!;
    }
    final pad = (maxY - minY) == 0 ? 5.0 : (maxY - minY) * 0.18;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      height: 170,
      child: LineChart(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
        LineChartData(
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY + pad - (minY - pad)) / 3,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: t.soft, strokeWidth: 1, dashArray: [3, 4]),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            if (purchase != null)
              LineChartBarData(
                spots: [FlSpot(0, purchase!), FlSpot(spots.length - 1.0, purchase!)],
                color: t.muted,
                barWidth: 1.5,
                dashArray: [6, 5],
                dotData: const FlDotData(show: false),
              ),
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: t.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (s, _) => s.x == spots.last.x,
                getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                    radius: 5,
                    color: t.money,
                    strokeWidth: 2,
                    strokeColor: t.line),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    t.accent.withValues(alpha: 0.22),
                    t.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => t.surface,
              tooltipBorder: BorderSide(color: t.line, width: 2),
              getTooltipItems: (touched) => touched.map((s) {
                if (s.barIndex == 0 && purchase != null) {
                  return LineTooltipItem(
                      'You paid\n${currency.format(s.y)}',
                      VText.body(11, t.muted));
                }
                final p = points[s.x.toInt().clamp(0, points.length - 1)];
                return LineTooltipItem(
                  '${p.at.day}/${p.at.month}/${p.at.year % 100}\n${currency.format(s.y)}',
                  VText.body(12, t.text, weight: FontWeight.w900),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
