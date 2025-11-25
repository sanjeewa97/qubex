import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'feed_page.dart';
import 'notes_page.dart';
import 'profile_page.dart';

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
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined), 
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primary),
            label: 'Feed'
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined), 
            selectedIcon: Icon(Icons.library_books_rounded, color: AppTheme.primary),
            label: 'Notes'
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline), 
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
            label: 'Me'
          ),
        ],
      ),
    );
  }
}
