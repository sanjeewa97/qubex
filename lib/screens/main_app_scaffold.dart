import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'feed_page.dart';
import 'notes_page.dart';
import 'profile_page.dart';
import 'chat_list_screen.dart';

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  @override
  void initState() {
    super.initState();
    _checkStreak();
  }

  void _checkStreak() {
    final user = AuthService().currentUser;
    if (user != null) {
      FirebaseService().updateUserStreak(user.uid);
    }
  }
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const FeedPage(),
    const NotesPage(),
    const ChatListScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
          ]
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, "Feed"),
              _buildNavItem(1, Icons.library_books_rounded, "Notes"),
              _buildNavItem(2, Icons.chat_bubble_rounded, "Chat", isBadge: true),
              _buildNavItem(3, Icons.person_rounded, "Me"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isBadge = false}) {
    final isSelected = _currentIndex == index;
    final user = AuthService().currentUser;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBadge)
              StreamBuilder<int>(
                // Use a different stream for chat unread count if available, or keep notification count for now?
                // Ideally we should have a getUnreadChatCount stream.
                // For now, let's use a placeholder or 0 until we implement unread chat count stream.
                // Actually, ChatListScreen handles its own badges inside.
                // But for the main tab badge, we need a stream of total unread chats.
                // Let's assume 0 for now to avoid errors, or create the stream.
                stream: Stream.value(0), // TODO: Implement getUnreadChatCount
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Badge(
                    isLabelVisible: count > 0 && !isSelected, // Hide badge dot when selected (optional, or keep it)
                    label: Text('$count'),
                    child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 26),
                  );
                },
              )
            else
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 26),
            
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
