import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../models/game.dart';
import '../../../core/currency_provider.dart';

class HistoricalPriceChart extends ConsumerWidget {
  final Game game;
  final List<Map<String, dynamic>> history;

  const HistoricalPriceChart({
    super.key,
    required this.game,
    required this.history,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, color: Colors.white24, size: 32),
            SizedBox(height: 8),
            Text(
              'Recording trend data...',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getPlatformColor(game.platform);

    // Extract relevant data points based on condition
    final spots = _getSpots();
    if (spots.length < 2) {
       return _buildSingleDataState(context, spots.first.y, accentColor, currency);
    }

    final minY = spots.map((s) => s.y).reduce(min);
    final maxY = spots.map((s) => s.y).reduce(max);
    final range = maxY - minY;
    final padding = range == 0 ? 10.0 : range * 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _StatItem(label: 'HISTORICAL HIGH', value: currency.format(maxY), color: Colors.greenAccent),
             _StatItem(label: 'HISTORICAL LOW', value: currency.format(minY), color: Colors.redAccent),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: minY - padding,
              maxY: maxY + padding,
              lineBarsData: [
                // baseline for purchase price
                if (game.purchasePrice != null)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, game.purchasePrice!),
                      FlSpot(spots.length - 1.0, game.purchasePrice!),
                    ],
                    isCurved: false,
                    color: Colors.white.withValues(alpha: 0.1),
                    dashArray: [5, 5],
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                  ),
                // main trend line
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: accentColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: accentColor,
                      strokeWidth: 1.5,
                      strokeColor: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.2),
                        accentColor.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => isDark ? const Color(0xFF1E1E22) : Colors.white,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      if (spot.barIndex == 0 && game.purchasePrice != null) {
                         return LineTooltipItem('Investment\n${currency.format(spot.y)}', const TextStyle(color: Colors.white54, fontSize: 10));
                      }
                      
                      final data = history[spot.x.toInt()];
                      final dateStr = _formatTimestamp(data['fetched_at']);
                      return LineTooltipItem(
                        '$dateStr\n${currency.format(spot.y)}',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getSpots() {
    return history.asMap().entries.map((e) {
      final data = e.value;
      double price = 0;
      if (game.platform.isDigital) {
        price = (data['price_digital'] as num?)?.toDouble() ?? 0;
      } else {
        switch (game.condition) {
          case GameCondition.loose:
            price = (data['price_loose'] as num?)?.toDouble() ?? 0;
            break;
          case GameCondition.cib:
          case GameCondition.boxed:
            price = (data['price_complete'] as num?)?.toDouble() ?? 0;
            break;
          case GameCondition.new_:
            price = (data['price_new'] as num?)?.toDouble() ?? 0;
            break;
        }
      }
      return FlSpot(e.key.toDouble(), price);
    }).where((s) => s.y > 0).toList();
  }

  Widget _buildSingleDataState(BuildContext context, double price, Color color, CurrencyState currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: color.withValues(alpha: 0.5), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRENDING DATA', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  'Currently stable at ${currency.format(price)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(AppPlatform p) {
    if (p.isPlayStation) return const Color(0xFF003087);
    if (p == AppPlatform.steam) return const Color(0xFF66C0F4);
    if (p == AppPlatform.nintendo) return const Color(0xFFE60012);
    return Colors.cyanAccent;
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.parse(ts.toString());
    return '${dt.day}/${dt.month}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
      ],
    );
  }
}
