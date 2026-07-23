import 'package:flutter/material.dart';
import 'app_theme.dart';

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: AppTheme.alertCritical),
              const SizedBox(height: AppTheme.spLg),
              Text('Akses Ditolak', style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface)),
              const SizedBox(height: AppTheme.spMd),
              Text('Anda tidak memiliki izin untuk mengakses halaman ini.',
                  style: AppTheme.bodyMd, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spXl),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
