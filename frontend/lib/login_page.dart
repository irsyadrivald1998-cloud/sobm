import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey               = GlobalKey<FormState>();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _urlController         = TextEditingController();
  bool  _isPasswordVisible     = false;
  bool  _isLoading             = false;

  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadBaseUrl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _checkLoginStatus() async {
    if (await _apiService.isLoggedIn()) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _loadBaseUrl() async {
    final url = await _apiService.getBaseUrl();
    _urlController.text = url;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await _apiService.saveBaseUrl(_urlController.text.trim());
    try {
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        _showSnack('Login berhasil', isError: false);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface)),
      backgroundColor:
          isError ? AppTheme.errorContainer : AppTheme.surfaceHighest,
    ));
  }

  void _showSettingsDialog() {
    final tempController = TextEditingController(text: _urlController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API BASE URL', style: AppTheme.labelMd),
            const SizedBox(height: AppTheme.spSm),
            TextField(
              controller: tempController,
              style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
              decoration:
                  const InputDecoration(hintText: 'http://192.168.x.x:8000'),
            ),
            const SizedBox(height: AppTheme.spSm),
            Text('Default: ${ApiService.defaultBaseUrl}',
                style: AppTheme.labelSm),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              tempController.text = ApiService.defaultBaseUrl;
              _urlController.text = ApiService.defaultBaseUrl;
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () {
              _urlController.text = tempController.text;
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Main Layout ──────────────────────────────────────────────
          isWide ? _buildWideLayout() : _buildNarrowLayout(),

          // ── Settings FAB ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.settings_outlined,
                  color: AppTheme.outline, size: 22),
              tooltip: 'Server Settings',
              onPressed: _showSettingsDialog,
            ),
          ),

          // ── Bottom Status Bar ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StatusBar(),
          ),
        ],
      ),
    );
  }

  // ── Wide (tablet / desktop) ───────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left decorative panel
        Expanded(
          flex: 5,
          child: _DecorativePanel(),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.background,
            child: _buildFormPanel(),
          ),
        ),
      ],
    );
  }

  // ── Narrow (phone) ────────────────────────────────────────────────────────
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Compact top banner
        _CompactBanner(),
        // Form scrollable
        Expanded(child: _buildFormPanel()),
      ],
    );
  }

  // ── Form Panel ────────────────────────────────────────────────────────────
  Widget _buildFormPanel() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spXl,
            AppTheme.spXl,
            AppTheme.spXl,
            80, // room for status bar
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting
                  Text('Selamat Datang',
                      style: AppTheme.headlineMd
                          .copyWith(color: AppTheme.onSurface)),
                  const SizedBox(height: AppTheme.spXs),
                  Text('Manajemen Gedung Cerdas',
                      style: AppTheme.bodyMd),
                  const SizedBox(height: AppTheme.spXl + AppTheme.spMd),

                  // ── Email ──────────────────────────────────────────
                  _buildInputField(
                    label: 'Email',
                    hint: 'employee@sobm.id',
                    controller: _emailController,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Email wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spMd),

                  // ── Password ───────────────────────────────────────
                  _buildInputField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppTheme.outline,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spXl),

                  // ── Masuk Button ───────────────────────────────────
                  _MasukButton(
                      isLoading: _isLoading, onPressed: _handleLogin),
                  const SizedBox(height: AppTheme.spXl),

                  // ── Divider "Atau" ─────────────────────────────────
                  _OrDivider(),
                  const SizedBox(height: AppTheme.spXl),

                  // ── Biometric Buttons ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _BiometricButton(
                          icon: Icons.face,
                          label: 'Face ID',
                          onPressed: () => _showSnack(
                              'Face ID belum tersedia',
                              isError: false),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spMd),
                      Expanded(
                        child: _BiometricButton(
                          icon: Icons.fingerprint,
                          label: 'Fingerprint',
                          onPressed: () => _showSnack(
                              'Fingerprint belum tersedia',
                              isError: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable labeled input ─────────────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.labelMd
                .copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 0.8)),
        const SizedBox(height: AppTheme.spXs + 2),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTheme.bodyLg.copyWith(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, size: 20, color: AppTheme.outline),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Left decorative panel for wide layout
class _DecorativePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF180A09), // surfaceLowest
            Color(0xFF2C1B1A), // surface
            Color(0xFF1E0F0E), // background
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Grid lines decoration
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Center content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon ring
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.primaryBrand.withOpacity(0.5),
                          width: 1.5),
                      color: AppTheme.primaryBrand.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.business,
                        size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: AppTheme.spLg),
                  Text(
                    'SOBM',
                    style: AppTheme.displayLg.copyWith(
                      color: AppTheme.onSurface,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spSm),
                  Text(
                    'Sistem Operasional\nBangunan & Manajemen',
                    style: AppTheme.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spXl),
                  // Decorative accent line
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrand,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact top banner for narrow (phone) layout
class _CompactBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF180A09), Color(0xFF2C1B1A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.primaryBrand.withOpacity(0.5),
                          width: 1.5),
                      color: AppTheme.primaryBrand.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.business,
                        size: 26, color: AppTheme.primary),
                  ),
                  const SizedBox(width: AppTheme.spMd),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SOBM',
                          style: AppTheme.headlineMd.copyWith(
                              letterSpacing: 4,
                              color: AppTheme.onSurface)),
                      Text('Manajemen Gedung Cerdas',
                          style: AppTheme.labelMd),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary "Masuk" button
class _MasukButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _MasukButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

/// "Atau" divider with lines on both sides
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 0.5, color: AppTheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd),
          child: Text(
            'Atau',
            style: AppTheme.labelMd.copyWith(color: AppTheme.outline),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 0.5, color: AppTheme.outlineVariant),
        ),
      ],
    );
  }
}

/// Biometric option button (Face ID / Fingerprint)
class _BiometricButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _BiometricButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
        side: const BorderSide(color: AppTheme.outlineVariant, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppTheme.primary),
          const SizedBox(height: AppTheme.spXs),
          Text(
            label,
            style: AppTheme.labelMd.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Bottom status bar — "Sistem Berjalan Normal"
class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spMd,
        vertical: AppTheme.spSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        border: const Border(
          top: BorderSide(color: AppTheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.statusOk,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.spSm),
            Text(
              'Sistem Berjalan Normal',
              style: AppTheme.labelMd.copyWith(color: AppTheme.statusOk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle blueprint grid background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.outlineVariant.withOpacity(0.15)
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
