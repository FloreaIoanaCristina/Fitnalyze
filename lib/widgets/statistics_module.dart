import 'package:fitnalyzer/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/workout_stats_data.dart';

class StatisticsModule extends StatelessWidget {
  final WorkoutStatsData stats;

  const StatisticsModule({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. CARD TOP STATS (Repetări Totale + Cel mai practicat exercițiu)
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: AppColors.card,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Center(
                    child: _buildStatItem('Repetări Totale',
                        '${stats.totalReps}', Icons.repeat, AppColors.accent),
                  ),
                ),
                Container(
                    height: 45,
                    width: 1,
                    color: AppColors.textSecondary.withOpacity(0.3)),
                Expanded(
                  child: Center(
                    child: _buildStatItem(
                        'Top Exercițiu',
                        stats.topExerciseName,
                        Icons.emoji_events,
                        AppColors.warning),
                  ),
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. GRAFIC LINE CHART (Evoluție Zilnică)
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: AppColors.card,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Evoluție Zilnică (Ultimele 7 Zile)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: _buildLineChart(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. GRAFIC PIE CHART (Distribuția Exercițiilor)
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: AppColors.card,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Distribuția Aprofundării Exercițiilor",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                stats.repsPerExercise.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Nu există date suficiente",
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: _buildPieChart(),
                          ),
                          const SizedBox(height: 16),
                          _buildPieChartLegend(),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment
          .center, // Centrare pe verticală în interiorul coloanei
      crossAxisAlignment:
          CrossAxisAlignment.center, // Centrare pe orizontală a copiilor
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis, // Previne overflow-ul la nume lungi
          textAlign: TextAlign
              .center, // Centrare text pe mai multe rânduri (dacă e cazul)
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final entries = stats.dailyReps.entries.toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < entries.length) {
                  final date = entries[index].key;
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire Pie Chart
  Widget _buildPieChart() {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
      Colors.teal,
    ];

    int colorIndex = 0;
    final total = stats.totalReps == 0 ? 1 : stats.totalReps.toDouble();

    final sections = stats.repsPerExercise.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 35,
        sections: sections,
      ),
    );
  }

  Widget _buildPieChartLegend() {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
      Colors.teal,
    ];

    int colorIndex = 0;

    return Center(
        // 1. Centrează întreg blocul legendei în pagină
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: stats.repsPerExercise.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                '${entry.key} (${entry.value})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      }).toList(),
    ));
  }
}
