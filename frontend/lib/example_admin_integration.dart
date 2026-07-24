// ═════════════════════════════════════════════════════════════════════════════
// CONTOH INTEGRASI ADMIN DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════
// File ini berisi contoh-contoh cara mengintegrasikan Admin Dashboard
// ke dalam aplikasi SOBM Mobile.

import 'package:flutter/material.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTOH 1: Redirect berdasarkan Role setelah Login
// ─────────────────────────────────────────────────────────────────────────────

class LoginPageExample extends StatelessWidget {
  final ApiService _apiService = ApiService();

  LoginPageExample({super.key});

  Future<void> _handleLogin(BuildContext context, String employeeId, String password) async {
    try {
      // Login via API
      final loginData = await _apiService.login(employeeId, password);
      final userData = loginData['user'] as Map<String, dynamic>;
      final userRole = userData['role'] as String;

      if (!context.mounted) return;

      // Redirect berdasarkan role
      if (userRole == 'admin' || userRole == 'viewer') {
        // Jika admin atau viewer, ke admin dashboard
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        // Jika worker, ke home page worker
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Implementation login UI...
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleLogin(context, 'ADMIN001', 'password'),
          child: const Text('Login as Admin'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTOH 2: Navigation dari HomePage Worker ke Admin Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class WorkerHomePageExample extends StatelessWidget {
  final ApiService _apiService = ApiService();

  WorkerHomePageExample({super.key});

  Future<void> _checkAdminAccess(BuildContext context) async {
    final user = await _apiService.getUser();
    final role = user?['role'] as String? ?? 'worker';

    if (!context.mounted) return;

    if (role == 'admin' || role == 'viewer') {
      // User punya akses admin, navigate ke dashboard
      Navigator.pushNamed(context, '/admin-dashboard');
    } else {
      // User tidak punya akses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak memiliki akses admin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Home')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _checkAdminAccess(context),
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Akses Admin Dashboard'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTOH 3: Bottom Navigation dengan Admin Access
// ─────────────────────────────────────────────────────────────────────────────

class MainNavigationExample extends StatefulWidget {
  const MainNavigationExample({super.key});

  @override
  State<MainNavigationExample> createState() => _MainNavigationExampleState();
}

class _MainNavigationExampleState extends State<MainNavigationExample> {
  final ApiService _apiService = ApiService();
  String _userRole = 'worker';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await _apiService.getUser();
    setState(() {
      _userRole = user?['role'] as String? ?? 'worker';
    });
  }

  void _onNavTap(int index) {
    if (index == 3 && (_userRole == 'admin' || _userRole == 'viewer')) {
      // Navigate to admin dashboard
      Navigator.pushNamed(context, '/admin-dashboard');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOBM App')),
      body: Center(child: Text('Current Tab: $_selectedIndex')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _userRole == 'admin' || _userRole == 'viewer'
                  ? Icons.admin_panel_settings
                  : Icons.person,
            ),
            label: _userRole == 'admin' || _userRole == 'viewer' 
                ? 'Admin' 
                : 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTOH 4: Drawer Menu dengan Admin Option
// ─────────────────────────────────────────────────────────────────────────────

class DrawerMenuExample extends StatelessWidget {
  final String userRole;

  const DrawerMenuExample({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Text(
              'SOBM Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('My Tasks'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to tasks
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Activity Log'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/activity-log');
            },
          ),
          // Admin-only menu item
          if (userRole == 'admin' || userRole == 'viewer')
            const Divider(),
          if (userRole == 'admin' || userRole == 'viewer')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin-dashboard');
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              final api = ApiService();
              await api.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTOH 5: Protected Route Middleware
// ─────────────────────────────────────────────────────────────────────────────

class AdminRouteGuard extends StatefulWidget {
  final Widget child;

  const AdminRouteGuard({
    super.key,
    required this.child,
  });

  @override
  State<AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final user = await _apiService.getUser();
      final role = user?['role'] as String? ?? 'worker';
      
      setState(() {
        _hasAccess = role == 'admin' || role == 'viewer';
        _isLoading = false;
      });

      if (!_hasAccess && mounted) {
        // Redirect to home if no access
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akses ditolak: Hanya admin yang dapat mengakses halaman ini'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasAccess) {
      return const Scaffold(
        body: Center(
          child: Text('Redirecting...'),
        ),
      );
    }

    return widget.child;
  }
}

// Usage dalam routes:
// '/admin-dashboard': (context) => AdminRouteGuard(
//   child: const AdminDashboardPage(),
// ),
