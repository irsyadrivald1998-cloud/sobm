import 'package:flutter/material.dart';
import 'api_service.dart';
import 'home_page_dashboard.dart';
import 'activity_log_page.dart';
import 'attendance_page.dart';
import 'profile_page.dart';
import 'app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePageDashboard(),
    const ActivityLogPage(),
    const AttendancePage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().getUser(); // Need to handle async here properly
    // For simplicity, assumed synchronous access in UI is problematic,
    // but the task is to limit UI.

    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService().getUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final user = snapshot.data!;
        final role = user['role'];
        final isUser = role == 'user';

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: isUser ? [_pages[1]] : _pages, // Only feed for user
          ),
        bottomNavigationBar: isUser ? null : BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceLowest,
            selectedItemColor: AppTheme.primaryBrand,
            unselectedItemColor: AppTheme.outline,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.feed_outlined),
                activeIcon: Icon(Icons.feed),
                label: 'Aktivitas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.co_present_outlined),
                activeIcon: Icon(Icons.co_present),
                label: 'Absensi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
