import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final TextEditingController _employeeIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.requestPasswordReset(
        employeeId: _employeeIdController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Lupa Password', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: _emailSent ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spXl),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(AppTheme.spLg),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrand.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 64,
              color: AppTheme.primaryBrand,
            ),
          ),
          const SizedBox(height: AppTheme.spLg),

          // Title
          Text(
            'Lupa Password?',
            style: AppTheme.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spSm),

          // Description
          Text(
            'Masukkan ID Pegawai Anda dan kami akan mengirimkan link reset password ke email terdaftar.',
            style: AppTheme.bodyMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spXl),

          // Employee ID Field
          Text('ID Pegawai', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spSm),
          TextFormField(
            controller: _employeeIdController,
            decoration: InputDecoration(
              hintText: 'Contoh: EMP001',
              prefixIcon: const Icon(Icons.badge),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'ID Pegawai harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spXl),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _sendResetLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
              disabledBackgroundColor: AppTheme.outline,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Kirim Link Reset'),
          ),
          const SizedBox(height: AppTheme.spMd),

          // Back to Login
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTheme.spXl * 2),
        
        // Success Icon
        Container(
          padding: const EdgeInsets.all(AppTheme.spLg),
          decoration: BoxDecoration(
            color: AppTheme.statusOk.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 64,
            color: AppTheme.statusOk,
          ),
        ),
        const SizedBox(height: AppTheme.spLg),

        // Success Title
        Text(
          'Email Terkirim!',
          style: AppTheme.headlineMd,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spSm),

        // Success Description
        Text(
          'Link reset password telah dikirim ke email terdaftar Anda. Silakan cek inbox atau folder spam.',
          style: AppTheme.bodyMd,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spXl),

        // Info Box
        Container(
          padding: const EdgeInsets.all(AppTheme.spMd),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.primaryBrand),
                  const SizedBox(width: AppTheme.spXs),
                  Text(
                    'Informasi Penting',
                    style: AppTheme.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBrand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spSm),
              Text('• Link reset akan kadaluarsa dalam 1 jam', style: AppTheme.bodyMd),
              const SizedBox(height: AppTheme.spXs),
              Text('• Jika tidak menerima email, coba kirim ulang', style: AppTheme.bodyMd),
              const SizedBox(height: AppTheme.spXs),
              Text('• Hubungi admin jika masalah berlanjut', style: AppTheme.bodyMd),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spXl),

        // Resend Button
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Kirim Ulang'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
          ),
        ),
        const SizedBox(height: AppTheme.spMd),

        // Back to Login
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBrand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
          ),
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }
}
