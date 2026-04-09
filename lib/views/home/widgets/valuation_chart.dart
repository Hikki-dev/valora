import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValuationChart extends ConsumerWidget {
  final List<ValueSnapshot> history;
  final bool hidePricing;

  const ValuationChart({
    super.key,
    required this.history,
    required this.hidePricing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) return const SizedBox.shrink();

    final currency = ref.read(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).primaryColor;

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24, bottom: 8, right: 16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: history.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.totalValue);
              }).toList(),
              isCurved: true,
              color: accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: accentColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => isDark ? const Color(0xFF1E1E22) : Colors.white,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = history[spot.x.toInt()].date;
                  final value = hidePricing ? '****' : currency.format(spot.y);
                  return LineTooltipItem(
                    '${date.day}/${date.month}\n$value',
                    TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
