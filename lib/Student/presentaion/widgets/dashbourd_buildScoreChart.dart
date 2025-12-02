import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/utils/app_colors.dart';

class ScoreChart extends StatelessWidget {
  final List<dynamic> courses;

  const ScoreChart({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {

    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < courses.length; i++) {
      final courseOffering = courses[i]["SectionCourseOffering"];
      if (courseOffering == null) continue;

      final sectionGrades =
          courseOffering["SectionGrade"] as List<dynamic>? ?? [];
      final firstGrade = sectionGrades.isNotEmpty ? sectionGrades[0] : null;

      double currentScore = (firstGrade?["Total"] ?? 0).toDouble();
      double predictedScore = (firstGrade?["PredictedTotal"] ?? 0).toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 14,
          barRods: [
            BarChartRodData(
              toY: currentScore,
              width: 14,
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.primaryGradient,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: AppColors.primaryBlue.withOpacity(0.1),
              ),
            ),
            BarChartRodData(
              toY: predictedScore,
              width: 14,
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.secondaryGradient,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: AppColors.secondaryOrange.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
      decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.primaryBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  width: 1.5,
                ),
        boxShadow: [
          BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
        ],
      ),
              padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            maxY: 100,
            groupsSpace: 30,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 40,
                  showTitles: true,
                  interval: 20,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= courses.length) return const Text("");
                    final name =
                        courses[index]["SectionCourseOffering"]?["Course"]
                        ?["Title"] ??
                            "";
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        name.length > 8 ? "${name.substring(0, 8)}…" : name,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.primaryBlue.withOpacity(0.12),
                strokeWidth: 0.8,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
            ),
          ),
        );
      },
    );
  }
}
