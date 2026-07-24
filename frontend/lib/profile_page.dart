import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: AppTheme.surfaceLowest,
      ),
      body: const Center(
        child: Text('Halaman profil'),
      ),
    );
  }
}
