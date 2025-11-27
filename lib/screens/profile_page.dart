import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import 'profile_setup_screen.dart';

import '../widgets/loading_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirebaseService firebaseService = FirebaseService();
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: Stream.fromFuture(firebaseService.getUser(user.uid)), // Ideally this should be a real stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          final userModel = snapshot.data;
          final name = userModel?.name ?? user.displayName ?? "User";
          final school = userModel?.school ?? "Unknown School";
          final photoUrl = userModel?.photoUrl.isNotEmpty == true ? userModel!.photoUrl : user.photoURL;

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null 
                              ? const Icon(Icons.person, size: 40, color: AppTheme.primary)
                              : null,
                          ).animate().scale(),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                Text(school, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                if (userModel != null && userModel.grade.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text("Grade ${userModel.grade} • ${userModel.age} Years • ${userModel.gender}", 
                                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSetupScreen()));
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                          )
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: "IQ Score", value: "${userModel?.iqScore ?? 0}"),
                          _StatItem(label: "Rank", value: userModel?.rank ?? "Novice"),
                          _StatItem(label: "Solved", value: "${userModel?.solvedCount ?? 0}"),
                        ],
                      ),
                    ],
                  ),
                ),

              // Achievements / Stats Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text("Achievements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const _AchievementItem(title: "First Question", desc: "Asked your first question", icon: Icons.star, color: Colors.amber),
                    const _AchievementItem(title: "Helper", desc: "Answered 5 questions", icon: Icons.handshake, color: Colors.blue),
                    const _AchievementItem(title: "Scholar", desc: "Uploaded 10 notes", icon: Icons.book, color: Colors.purple),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await authService.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ).animate().fadeIn().slideY(begin: 0.5, end: 0);
  }
}

class _AchievementItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _AchievementItem({required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
