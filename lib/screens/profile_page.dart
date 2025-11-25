import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary,
                    child: Text("C", style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Chamath Jayasuriya", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Royal College • Physical Science", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem("420", "IQ Score"),
                      _StatItem("Genius", "Rank"),
                      _StatItem("15", "Solved"),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Achievements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _AchievementItem(icon: Icons.star, color: Colors.amber, title: "Top Contributor", subtitle: "Verified 50+ Answers"),
                  _AchievementItem(icon: Icons.emoji_events, color: Colors.purple, title: "Maths Whiz", subtitle: "Won Monthly Challenge"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AchievementItem({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
