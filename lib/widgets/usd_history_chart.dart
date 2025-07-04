import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/rate.dart';

class UsdHistoryChart extends StatelessWidget {
  final List<Rate> rates;

  const UsdHistoryChart({super.key, required this.rates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (rates.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No USD history')));
    }

    final sortedRates = [...rates]..sort((a, b) => a.updated!.compareTo(b.updated!));

    final spotsBuy = sortedRates
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.buying ?? 0))
        .toList();

    final spotsSell = sortedRates
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.selling ?? 0))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USD Rate History',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (LineBarSpot touchedSpot) => colorScheme.surfaceVariant,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final date = sortedRates[spot.spotIndex].updated!;
                      final label = spot.bar.color == colorScheme.primary ? 'Buy' : 'Sell';
                      return LineTooltipItem(
                        '$label\n${date.month}/${date.day}: ${spot.y.toStringAsFixed(2)}',
                        theme.textTheme.labelMedium!.copyWith(color: colorScheme.onSurface),
                      );
                    }).toList(),
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((i) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: colorScheme.primary.withOpacity(0.3), strokeWidth: 1),
                      FlDotData(show: true),
                    );
                  }).toList(),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedRates.length) {
                          final date = sortedRates[index].updated!;
                          return Text(
                            '${date.month}/${date.day}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: spotsBuy,
                    color: colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    isCurved: true,
                    spots: spotsSell,
                    color: colorScheme.secondary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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