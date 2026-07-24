import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Call API to update profile
      await _apiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppTheme.statusOk,
          ),
        );
        Navigator.of(context).pop(true); // Return true to refresh profile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.alertCritical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBrand.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppTheme.primaryBrand.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _getRoleIcon(widget.user['role'] ?? 'worker'),
                        size: 48,
                        color: AppTheme.primaryBrand,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBrand,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spSm),
              Center(
                child: Text(
                  'Tap untuk ubah foto',
                  style: AppTheme.labelMd.copyWith(
                    color: AppTheme.primaryBrand,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spXl),

              // Read-only fields
              Text('Informasi Akun', style: AppTheme.headlineSm),
              const SizedBox(height: AppTheme.spMd),

              // Employee ID (Read-only)
              _ReadOnlyField(
                label: 'ID Pegawai',
                value: widget.user['employee_id'] ?? '-',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppTheme.spMd),

              // Role (Read-only)
              _ReadOnlyField(
                label: 'Role',
                value: _getRoleLabel(widget.user['role'] ?? 'worker'),
                icon: Icons.work_outline,
              ),
              const SizedBox(height: AppTheme.spMd),

              // Company (Read-only)
              _ReadOnlyField(
                label: 'Perusahaan',
                value: widget.user['company'] ?? '-',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: AppTheme.spXl),

              // Editable fields
              Text('Informasi Pribadi', style: AppTheme.headlineSm),
              const SizedBox(height: AppTheme.spMd),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (value.trim().length < 3) {
                    return 'Nama minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spMd),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'nama@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spMd),

              // Phone field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 10) {
                      return 'Nomor telepon minimal 10 digit';
                    }
                    final phoneRegex = RegExp(r'^[0-9+]+$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Nomor telepon hanya boleh angka';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spXl),

              // Save button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: AppTheme.spMd),

              // Cancel button
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    return switch (role) {
      'admin' => Icons.admin_panel_settings,
      'viewer' => Icons.visibility,
      'osb' => Icons.engineering,
      'resepsionis' => Icons.support_agent,
      _ => Icons.person,
    };
  }

  String _getRoleLabel(String role) {
    return switch (role) {
      'admin' => 'Administrator',
      'viewer' => 'Viewer',
      'housekeeping' => 'Housekeeping',
      'teknisi' => 'Teknisi',
      'security' => 'Security',
      'osb' => 'OSB',
      'resepsionis' => 'Resepsionis',
      'bm' => 'Building Manager',
      'user' => 'User',
      _ => role.toUpperCase(),
    };
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spSm),
            decoration: BoxDecoration(
              color: AppTheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppTheme.outline),
          ),
          const SizedBox(width: AppTheme.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
