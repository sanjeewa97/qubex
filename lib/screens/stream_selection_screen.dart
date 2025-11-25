import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_app_scaffold.dart';

class StreamSelectionScreen extends StatelessWidget {
  const StreamSelectionScreen({super.key});

  final List<Map<String, dynamic>> streams = const [
    {"name": "Physical Science", "icon": Icons.calculate, "color": Colors.red},
    {"name": "Bio Science", "icon": Icons.biotech, "color": Colors.green},
    {"name": "Technology", "icon": Icons.computer, "color": Colors.orange},
    {"name": "Commerce", "icon": Icons.bar_chart, "color": Colors.blue},
    {"name": "Arts", "icon": Icons.palette, "color": Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text("Select Stream"),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "We curate your feed based on your A/L Stream.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: streams.length,
              itemBuilder: (context, index) {
                final s = streams[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to Main App
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const MainAppScaffold()), 
                      (route) => false
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (s['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(s['icon'], color: s['color']),
                        ),
                        const SizedBox(width: 16),
                        Text(s['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
