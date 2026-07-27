import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController      = TextEditingController();
  bool  _isPasswordVisible  = false;
  bool  _isLoading          = false;
  bool  _rememberDevice     = false;

  final _apiService = ApiService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadBaseUrl();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _fadeController.dispose();
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
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
      backgroundColor:
          isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: Stack(
        children: [
          // Main scrollable content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        // ── White Card ──────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── Logo ───────────────────────────
                                  _buildLogo(),
                                  const SizedBox(height: 24),

                                  // ── Title ──────────────────────────
                                  const Text(
                                    'Selamat Datang',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // ── Subtitle ──────────────────────
                                  Text.rich(
                                    TextSpan(
                                      text: 'Masuk untuk melanjutkan.\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF7A7A8E),
                                        height: 1.6,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Syarat dan Kebijakan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 36),

                                  // ── Email ──────────────────────────
                                  _buildLabel('ID'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'ID Karyawan',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Email wajib diisi'
                                            : null,
                                  ),
                                  const SizedBox(height: 22),

                                  // ── Password ──────────────────────
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildLabel('KATA SANDI'),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context)
                                              .pushNamed('/forgot-password');
                                        },
                                        child: const Text(
                                          'Lupa?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFD32F2F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: '••••••••',
                                    obscureText: !_isPasswordVisible,
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() =>
                                          _isPasswordVisible =
                                              !_isPasswordVisible),
                                      child: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: const Color(0xFFAAAAAA),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Password wajib diisi'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // ── Remember Device ───────────────
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _rememberDevice = !_rememberDevice),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                              color: _rememberDevice
                                                  ? const Color(0xFFD32F2F)
                                                  : const Color(0xFFD0D0D0),
                                              width: 1.5,
                                            ),
                                            color: _rememberDevice
                                                ? const Color(0xFFD32F2F)
                                                : Colors.transparent,
                                          ),
                                          child: _rememberDevice
                                              ? const Icon(Icons.check,
                                                  size: 14,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Ingat perangkat ini',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5A5A6E),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Masuk Button ──────────────────
                                  _buildLoginButton(),
                                  const SizedBox(height: 16),

                                  // ── Daftar Button ─────────────────
                                  _buildRegisterButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Social Login Section ────────────────────
                        _buildSocialLoginSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Settings FAB ───────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Color(0xFFB0B0B0), size: 22),
              tooltip: 'Server Settings',
              onPressed: _showSettingsDialog,
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 90,
        height: 90,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 36,
              color: Color(0xFF1A1A2E),
            ),
          );
        },
      ),
    );
  }

  // ── Label ──────────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Text Field ────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A2E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          color: Color(0xFFBBBBCC),
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minHeight: 20, minWidth: 20),
        filled: true,
        fillColor: const Color(0xFFF8F8FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFE8E8EE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFD32F2F), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
      ),
      validator: validator,
    );
  }

  // ── Login Button ──────────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: const Color(0xFFD32F2F).withValues(alpha: 0.3),
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
                'Masuk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ── Register Button (dashed border) ───────────────────────────────────────
  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/register');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A2E),
          side: const BorderSide(
            color: Color(0xFFBBC8E8),
            width: 1,
            style: BorderStyle.solid,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text.rich(
          TextSpan(
            text: 'Belum punya akun? ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A7A8E),
            ),
            children: [
              TextSpan(
                text: 'Daftar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Social Login Section ──────────────────────────────────────────────────
  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        const Text(
          'ATAU LANJUT DENGAN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFAAAAAA),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              iconSize: 28,
              onTap: () =>
                  _showSnack('Google login belum tersedia', isError: false),
            ),
            const SizedBox(width: 16),
            _SocialButton(
              icon: Icons.apple_rounded,
              iconSize: 24,
              onTap: () =>
                  _showSnack('Apple login belum tersedia', isError: false),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Social login icon button
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 60,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8E8EE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: const Color(0xFF3A3A4E),
            ),
          ),
        ),
      ),
    );
  }
}
