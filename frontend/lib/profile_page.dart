import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ThemeProvider;
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String _errorMessage = '';
  File? _avatarFile;
  bool _isUploadingAvatar = false;
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final baseUrl = await _apiService.getBaseUrl();
      final userData = await _apiService.getUser();
      if (mounted) {
        setState(() {
          _baseUrl = baseUrl;
          _user = userData;
          _isLoading = false;
          _avatarFile = null; // Clear local file when loading from server
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showPhotoOptions() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spMd),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spMd),
            Text('Pilih Sumber Foto', style: AppTheme.headlineSm),
            const SizedBox(height: AppTheme.spMd),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBrand),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBrand),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: AppTheme.spSm),
          ],
        ),
      ),
    );

    if (result != null) {
      await _pickAndUploadPhoto(result);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _avatarFile = File(pickedFile.path);
        _isUploadingAvatar = true;
      });

      // Upload avatar to backend
      await _apiService.updateAvatar(pickedFile.path);
      
      // Reload user data to get the new avatar URL
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diubah'),
            backgroundColor: AppTheme.statusOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah foto: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.alertCritical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: Text('Apakah Anda yakin ingin keluar?', style: AppTheme.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              nav.pop(); // Close dialog
              await _apiService.logout();
              nav.pushReplacementNamed('/'); // Go to login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertCritical,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profil Pengguna', style: AppTheme.titleLg),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildProfile(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.alertCritical),
            const SizedBox(height: AppTheme.spMd),
            Text(_errorMessage, style: AppTheme.bodyLg, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spLg),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final name = _user?['name'] ?? 'Nama tidak tersedia';
    final employeeId = _user?['employee_id'] ?? '-';
    final email = _user?['email'] ?? '-';
    final role = _user?['role'] ?? 'worker';
    final company = _user?['company'] ?? '-';
    final createdAt = _user?['created_at'] as String?;
    final avatarUrl = _user?['avatar'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spLg),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
            ),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _showPhotoOptions,
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
                          image: _avatarFile != null
                              ? DecorationImage(
                                  image: FileImage(_avatarFile!),
                                  fit: BoxFit.cover,
                                )
                              : (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage('$_baseUrl/storage/$avatarUrl'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_avatarFile == null && (avatarUrl == null || avatarUrl.isEmpty))
                            ? Icon(
                                _getRoleIcon(role),
                                size: 48,
                                color: AppTheme.primaryBrand,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrand,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surface,
                              width: 2,
                            ),
                          ),
                          child: _isUploadingAvatar
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spMd),

                // Name
                Text(
                  name,
                  style: AppTheme.headlineMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spXs),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spMd,
                    vertical: AppTheme.spXs,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: _getRoleColor(role).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _getRoleLabel(role),
                    style: AppTheme.labelMd.copyWith(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spLg),

          // Account Information
          Text('Informasi Akun', style: AppTheme.headlineSm),
          const SizedBox(height: AppTheme.spMd),

          _InfoCard(
            icon: Icons.badge_outlined,
            label: 'ID Pegawai',
            value: employeeId,
          ),
          const SizedBox(height: AppTheme.spSm),

          _InfoCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          const SizedBox(height: AppTheme.spSm),

          _InfoCard(
            icon: Icons.business_outlined,
            label: 'Perusahaan',
            value: company,
          ),
          
          if (createdAt != null) ...[
            const SizedBox(height: AppTheme.spSm),
            _InfoCard(
              icon: Icons.calendar_today_outlined,
              label: 'Bergabung Sejak',
              value: _formatDate(createdAt),
            ),
          ],

          const SizedBox(height: AppTheme.spXl),

          // Quick Actions
          Text('Pengaturan', style: AppTheme.headlineSm),
          const SizedBox(height: AppTheme.spMd),

          // Theme Toggle - LIGHT MODE SWITCH
          Container(
            padding: const EdgeInsets.all(AppTheme.spMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spSm),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrand.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.brightness_6,
                    size: 20,
                    color: AppTheme.primaryBrand,
                  ),
                ),
                const SizedBox(width: AppTheme.spMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Terang',
                        style: AppTheme.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ThemeProvider.of(context).isLight ? 'Aktif' : 'Nonaktif',
                        style: AppTheme.labelSm.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: ThemeProvider.of(context).isLight,
                  onChanged: (value) {
                    ThemeProvider.of(context).toggle();
                  },
                  activeColor: AppTheme.primaryBrand,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spSm),

          _ActionButton(
            icon: Icons.lock_outline,
            label: 'Ubah Password',
            onTap: () {
              // TODO: Navigate to change password page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur ubah password akan segera tersedia')),
              );
            },
          ),
          const SizedBox(height: AppTheme.spSm),

          _ActionButton(
            icon: Icons.person_outline,
            label: 'Edit Profil',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(user: _user!),
                ),
              ).then((updated) {
                if (updated == true) {
                  _loadUserData(); // Refresh user data
                }
              });
            },
          ),
          const SizedBox(height: AppTheme.spSm),

          _ActionButton(
            icon: Icons.cloud_queue_outlined,
            label: 'Antrian Offline',
            onTap: () {
              Navigator.of(context).pushNamed('/offline-queue');
            },
          ),
          const SizedBox(height: AppTheme.spSm),

          _ActionButton(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SOBM',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.business, size: 48, color: AppTheme.primaryBrand),
                children: [
                  Text('Smart Office Building Management', style: AppTheme.bodyMd),
                  const SizedBox(height: AppTheme.spSm),
                  Text('Sistem manajemen gedung cerdas untuk operasional yang lebih efisien.', style: AppTheme.bodyMd),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spXl),

          // Logout Button
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertCritical,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
            ),
          ),
          const SizedBox(height: AppTheme.spMd),
        ],
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

  Color _getRoleColor(String role) {
    return switch (role) {
      'admin' => AppTheme.alertCritical,
      'viewer' => AppTheme.tertiary,
      'osb' => AppTheme.statusWarning,
      'resepsionis' => AppTheme.secondary,
      _ => AppTheme.primaryBrand,
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spSm),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBrand),
          ),
          const SizedBox(width: AppTheme.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelMd),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spMd),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.onSurface),
            const SizedBox(width: AppTheme.spMd),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }
}
