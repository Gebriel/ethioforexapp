import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rate.dart';

class UsdHistoryChart extends StatelessWidget {
  final List<Rate> rates;

  const UsdHistoryChart({super.key, required this.rates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (rates.isEmpty) {
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
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: colorScheme.outline.withAlpha((255 * 0.3).round()),
                ),
                const SizedBox(height: 12),
                Text(
                  'No USD history available',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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

    // Calculate min and max values for better scaling
    final allValues = [
      ...spotsBuy.map((e) => e.y),
      ...spotsSell.map((e) => e.y),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 0.5;

    // Create date labels
    final dateFormat = sortedRates.length <= 7
        ? DateFormat('M/d')
        : DateFormat('M/d');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USD Rate History',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              // Legend
              Row(
                children: [
                  _buildLegendItem(
                    color: colorScheme.primary,
                    label: 'Buy',
                    textStyle: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    color: colorScheme.secondary,
                    label: 'Sell',
                    textStyle: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                clipData: FlClipData.all(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedRates.length) {
                          final date = sortedRates[index].updated!;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dateFormat.format(date),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: sortedRates.length > 7 ? 2 : 1,
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withAlpha((255 * 0.1).round()),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Buy line
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.3,
                    spots: spotsBuy,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    preventCurveOverShooting: true,
                    color: colorScheme.primary,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == spotsBuy.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 6 : 4,
                          color: colorScheme.primary,
                          strokeColor: colorScheme.surface,
                          strokeWidth: isLast ? 3 : 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withAlpha((255 * 0.15).round()),
                          colorScheme.primary.withAlpha((255 * 0.05).round()),
                          colorScheme.primary.withAlpha((255 * 0.0).round()),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Sell line
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.3,
                    spots: spotsSell,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    preventCurveOverShooting: true,
                    color: colorScheme.secondary,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == spotsSell.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 6 : 4,
                          color: colorScheme.secondary,
                          strokeColor: colorScheme.surface,
                          strokeWidth: isLast ? 3 : 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary.withAlpha((255 * 0.1).round()),
                          colorScheme.secondary.withAlpha((255 * 0.03).round()),
                          colorScheme.secondary.withAlpha((255 * 0.0).round()),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final date = sortedRates[barSpot.spotIndex].updated!;
                        final label = barSpot.barIndex == 0 ? 'Buy' : 'Sell';
                        final dateStr = DateFormat('M/d').format(date);
                        return LineTooltipItem(
                          '$label $dateStr\n${barSpot.y.toStringAsFixed(2)}',
                          textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ) ?? const TextStyle(),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: colorScheme.primary.withAlpha((255 * 0.3).round()),
                          strokeWidth: 2,
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 8,
                              color: barData.color ?? colorScheme.primary,
                              strokeColor: colorScheme.surface,
                              strokeWidth: 3,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required TextStyle? textStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}