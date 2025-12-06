import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/iq_history_model.dart';
import '../services/firebase_service.dart';

class StatsTab extends StatelessWidget {
  final UserModel user;

  const StatsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Summary Cards
          Row(
            children: [
              _buildStatCard(
                context,
                "Daily Streak", 
                "${user.streakCount}", 
                Icons.local_fire_department_rounded, 
                Colors.orange
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                "Current IQ", 
                "${user.iqScore}", 
                Icons.psychology_rounded, 
                AppTheme.primary
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 2. IQ Progress Chart
          const Text(
            "IQ Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: StreamBuilder<List<IQHistoryModel>>(
              stream: FirebaseService().getIQHistory(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final history = snapshot.data ?? [];
                
                // Add current score as the latest point if history is empty or old
                List<IQHistoryModel> data = List.from(history);
                if (data.isEmpty) {
                  data.add(IQHistoryModel(date: DateTime.now(), score: user.iqScore));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < data.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(data[value.toInt()].date),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 22,
                          interval: 1, // Show all dates? Maybe adjust interval based on length
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 0,
                    // maxY: (data.map((e) => e.score).reduce(max) * 1.2).toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.score.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: AppTheme.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ).animate().scale(delay: 200.ms),

          const SizedBox(height: 30),

          // 3. Badges Grid (Mockup for now, or move existing logic here)
          const Text(
            "Badges Earned",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
               _buildBadge("Novice", Icons.star_outline, Colors.grey),
               if (user.iqScore > 100) _buildBadge("Scholar", Icons.school, Colors.blue),
               if (user.iqScore > 500) _buildBadge("Genius", Icons.psychology, Colors.purple),
               if (user.streakCount > 3) _buildBadge("Consistent", Icons.local_fire_department, Colors.orange),
               if (user.streakCount > 7) _buildBadge("Unstoppable", Icons.bolt, Colors.red),
               // Placeholder for locked
               _buildLockedBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ).animate().slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildBadge(String name, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildLockedBadge() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, color: Colors.grey[400], size: 28),
          const SizedBox(height: 8),
          Text("???", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
