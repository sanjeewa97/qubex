import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'feed_page.dart';
import 'notes_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const FeedPage(),
    const NotesPage(),
    const NotificationsPage(),
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
              _buildNavItem(2, Icons.notifications_rounded, "Alerts", isBadge: true),
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
                stream: user != null ? FirebaseService().getUnreadNotificationCount(user.uid) : Stream.value(0),
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
