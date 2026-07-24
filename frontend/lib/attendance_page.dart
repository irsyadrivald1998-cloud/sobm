import 'package:flutter/material.dart';
import 'app_theme.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppTheme.primaryBrand,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Attendance Page - Coming Soon'),
      ),
    );
  }
}
