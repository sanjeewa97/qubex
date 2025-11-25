import 'package:flutter/material.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Knowledge Hub")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Select Subject", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SubjectCard(title: "Maths", color: Colors.red.shade100, icon: Icons.calculate, iconColor: Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _SubjectCard(title: "Physics", color: Colors.blue.shade100, icon: Icons.speed, iconColor: Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Recent Uploads", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          _NoteTile(title: "Organic Chemistry Map", author: "Nimali D.", size: "2.4 MB"),
          _NoteTile(title: "Electronics Logic Gates", author: "Kamal S.", size: "1.1 MB"),
          _NoteTile(title: "2023 Past Paper Structure", author: "Qubex Team", size: "500 KB"),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _SubjectCard({required this.title, required this.color, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final String title;
  final String author;
  final String size;

  const _NoteTile({required this.title, required this.author, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("$author • $size", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.download_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}
