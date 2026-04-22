import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/mock/mock_analytics.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/widgets/info_card.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockAnalytics.sample();
    final spots = data.dailySeries
        .map((e) => FlSpot(e.x, e.y))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ListView(
        children: [
          InfoCard(
            title: 'Total Followers',
            value: data.totalFollowers.toString(),
            subtitle: 'All-time (mock)',
            icon: Icons.groups_2_rounded,
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Growth Today',
            value: '+${data.growthToday}',
            subtitle: 'vs. yesterday (mock)',
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Weekly Growth',
            value: '+${data.weeklyGrowth}',
            subtitle: 'Last 7 days (mock)',
            icon: Icons.calendar_view_week_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'Engagement trend',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 80,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppTheme.outline.withValues(alpha: 0.6),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, m) => Text(
                            v.toInt().toString(),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'D${v.toInt() + 1}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppTheme.accentSecondary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (s, p, b, i) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.accent,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentSecondary.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
