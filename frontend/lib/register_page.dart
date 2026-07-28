import 'package:flutter/material.dart';
import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'housekeeping';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final _apiService = ApiService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, Map<String, dynamic>> _jobMeta = {
    'housekeeping': {
      'title': 'Housekeeping & Kebersihan',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFF00A86B),
      'prefix': 'hk_',
      'description':
          'Fokus penugasan: Pembersihan area, sanitasi fasilitas, dan pengelolaan kelengkapan kebersihan gedung.',
      'badge': 'Operasional Kebersihan',
    },
    'teknisi': {
      'title': 'Teknisi & Engineering',
      'icon': Icons.build_rounded,
      'color': Color(0xFF0288D1),
      'prefix': 'tk_',
      'description':
          'Fokus penugasan: Perbaikan AC, kelistrikan, sistem air/plumbing, dan pemeliharaan perangkat fasilitas gedung.',
      'badge': 'Teknis & Maintenance',
    },
    'security': {
      'title': 'Security & Keamanan',
      'icon': Icons.security_rounded,
      'color': Color(0xFFD32F2F),
      'prefix': 'sec_',
      'description':
          'Fokus penugasan: Patroli keamanan gedung, pencatatan pengunjung, pengawasan pos, dan tanggap darurat.',
      'badge': 'Pengamanan & Patroli',
    },
    'osb': {
      'title': 'Operational Support Body (OSB)',
      'icon': Icons.support_agent_rounded,
      'color': Color(0xFFED6C02),
      'prefix': 'osb_',
      'description':
          'Fokus penugasan: Support logistik gedung, persiapan ruang rapat/event, dan koordinasi bantuan lapangan.',
      'badge': 'Dukungan Operasional',
    },
    'resepsionis': {
      'title': 'Resepsionis & Front Office',
      'icon': Icons.desk_rounded,
      'color': Color(0xFF9C27B0),
      'prefix': 'resep_',
      'description':
          'Fokus penugasan: Pelayanan tamu, registrasi kunjungan, layanan informasi, dan penerimaan surat/paket.',
      'badge': 'Layanan Garis Depan',
    },
    'bm': {
      'title': 'Building Manager (BM)',
      'icon': Icons.manage_accounts_rounded,
      'color': Color(0xFF1976D2),
      'prefix': 'bm_',
      'description':
          'Fokus penugasan: Pengawasan seluruh operasional gedung, manajemen jadwal, dan persetujuan kendala.',
      'badge': 'Manajemen Gedung',
    },
    'user': {
      'title': 'Staf General / User',
      'icon': Icons.person_rounded,
      'color': Color(0xFF455A64),
      'prefix': 'user_',
      'description':
          'Fokus penugasan: Penggunaan umum fasilitas gedung, pelaporan kendala/isu, dan riwayat presensi.',
      'badge': 'Pengguna Umum',
    },
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    _applyDefaultPrefix('housekeeping');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _applyDefaultPrefix(String role) {
    final prefix = _jobMeta[role]?['prefix'] ?? '';
    if (_employeeIdController.text.isEmpty ||
        _employeeIdController.text.startsWith('hk_') ||
        _employeeIdController.text.startsWith('tk_') ||
        _employeeIdController.text.startsWith('sec_') ||
        _employeeIdController.text.startsWith('osb_') ||
        _employeeIdController.text.startsWith('resep_') ||
        _employeeIdController.text.startsWith('bm_') ||
        _employeeIdController.text.startsWith('user_')) {
      _employeeIdController.text = prefix;
      _employeeIdController.selection = TextSelection.fromPosition(
        TextPosition(offset: _employeeIdController.text.length),
      );
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _apiService.register(
        name: _nameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        role: _selectedRole,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        _showSnack('Registrasi berhasil! Selamat datang.', isError: false);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMeta = _jobMeta[_selectedRole]!;
    final Color jobColor = currentMeta['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pendaftaran Akun',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Icon & Title
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: jobColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        currentMeta['icon'] as IconData,
                                        color: jobColor,
                                        size: 26,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Daftar Karyawan Baru',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Sistem Operasional Gedung (SOBM)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF7A7A8E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Job Role Dropdown Selection
                            Text(
                              'JOB / JABATAN KARYAWAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5A5A6E),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8F8FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8E8EE),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8E8EE),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: jobColor,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: _jobMeta.entries.map((entry) {
                                final key = entry.key;
                                final val = entry.value;
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Row(
                                    children: [
                                      Icon(
                                        val['icon'] as IconData,
                                        size: 20,
                                        color: val['color'] as Color,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          val['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRole = val;
                                    _applyDefaultPrefix(val);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            // Dynamic Role Description & Badge Box
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: jobColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: jobColor.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: jobColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          currentMeta['badge'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentMeta['description'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: const Color(0xFF3A3A4E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Employee Name Field
                            _buildLabel('NAMA LENGKAP'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                              textCapitalization: TextCapitalization.words,
                              decoration: _buildInputDecoration(
                                hint: 'Masukkan nama lengkap karyawan',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Nama lengkap tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Employee ID / NIP Field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabel('ID KARYAWAN / NIP'),
                                Text(
                                  'Format default: ${currentMeta['prefix']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: jobColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _employeeIdController,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                hint:
                                    'Contoh: ${currentMeta['prefix']}001',
                                icon: Icons.badge_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'ID Karyawan tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            _buildLabel('EMAIL (OPSIONAL)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              decoration: _buildInputDecoration(
                                hint: 'contoh@domain.com',
                                icon: Icons.email_outlined,
                              ),
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    !v.contains('@')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone Field
                            _buildLabel('NOMOR TELEPON / WA (OPSIONAL)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: TextInputType.phone,
                              decoration: _buildInputDecoration(
                                hint: '08123456789',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildLabel('PASSWORD'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                              obscureText: !_isPasswordVisible,
                              decoration: _buildInputDecoration(
                                hint: 'Minimal 8 karakter',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF7A7A8E),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (v.length < 8) {
                                  return 'Password minimal 8 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            _buildLabel('KONFIRMASI PASSWORD'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmPasswordController,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: _buildInputDecoration(
                                hint: 'Ulangi password di atas',
                                icon: Icons.lock_clock_outlined,
                                suffix: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF7A7A8E),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Konfirmasi password tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Register Submit Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Daftar Sekarang',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation Back to Login Page
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah memiliki akun? ',
                          style: TextStyle(
                            color: Color(0xFF7A7A8E),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5A5A6E),
        letterSpacing: 1.0,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF7A7A8E), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
    );
  }
}
