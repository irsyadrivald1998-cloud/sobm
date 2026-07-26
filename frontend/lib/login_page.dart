import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController      = TextEditingController();
  bool  _isPasswordVisible  = false;
  bool  _isLoading          = false;

  final _apiService = ApiService();

  late AnimationController _bgController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final FocusNode _emailFocus    = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadBaseUrl();

    // Slow-rotating background gradient
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Fade-in + slide-up entrance
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Pulse for logo ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _bgController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
                style: AppTheme.bodyMd.copyWith(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor:
          isError ? AppTheme.errorContainer : const Color(0xFF2E7D32),
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
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Animated gradient background ───────────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) => _AnimatedBackground(
              progress: _bgController.value,
            ),
          ),

          // ── Floating particles ─────────────────────────────────────
          const _FloatingParticles(),

          // ── Main content ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildLoginCard(),
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
              icon: Icon(Icons.settings_outlined,
                  color: Colors.white.withValues(alpha: 0.4), size: 22),
              tooltip: 'Server Settings',
              onPressed: _showSettingsDialog,
            ),
          ),
        ],
      ),
    );
  }

  // ── Glass Login Card ──────────────────────────────────────────────────────
  Widget _buildLoginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBrand.withValues(alpha: 0.08),
              blurRadius: 60,
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animated Logo ─────────────────────────────────
                  _buildAnimatedLogo(),
                  const SizedBox(height: 28),

                  // ── Title ─────────────────────────────────────────
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFB3AC),
                        Color(0xFFFF6B6B),
                        Color(0xFFFFB3AC),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'SOBM',
                      style: AppTheme.displayLg.copyWith(
                        color: Colors.white,
                        letterSpacing: 8,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistem Operasional Bangunan & Manajemen',
                    style: AppTheme.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // ── Divider ───────────────────────────────────────
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryBrand.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Welcome text ──────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang 👋',
                          style: AppTheme.headlineSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masuk ke akun Anda untuk melanjutkan',
                          style: AppTheme.bodyMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email Field ───────────────────────────────────
                  _GlowingInputField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    label: 'Email',
                    hint: 'employee@sobm.id',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Email wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 18),

                  // ── Password Field ────────────────────────────────
                  _GlowingInputField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Forgot Password ───────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      child: Text(
                        'Lupa Password?',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Login Button ──────────────────────────────────
                  _ShimmerLoginButton(
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 28),

                  // ── Version info ──────────────────────────────────
                  Text(
                    'Sistem Berjalan Normal  •  v1.0',
                    style: AppTheme.labelMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Animated Logo ─────────────────────────────────────────────────────────
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryBrand.withValues(alpha: 0.15 * _pulseAnimation.value),
                Colors.transparent,
              ],
              radius: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrand.withValues(alpha: 0.2 * _pulseAnimation.value),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBrand.withValues(alpha: 0.4 + 0.3 * _pulseAnimation.value),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBrand.withValues(alpha: 0.15),
                  AppTheme.primaryBrand.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated gradient background with moving color blobs
class _AnimatedBackground extends StatelessWidget {
  final double progress;
  const _AnimatedBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final angle = progress * 2 * pi;

    return Stack(
      children: [
        // Base dark background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0F),
                Color(0xFF12060A),
                Color(0xFF0F0A14),
              ],
            ),
          ),
        ),

        // Moving red/crimson blob top-right
        Positioned(
          top: -100 + 50 * sin(angle),
          right: -80 + 40 * cos(angle),
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryBrand.withValues(alpha: 0.12),
                  AppTheme.primaryBrand.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Moving purple blob bottom-left
        Positioned(
          bottom: -60 + 30 * cos(angle + 1.5),
          left: -60 + 40 * sin(angle + 1.5),
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                  const Color(0xFF7C4DFF).withValues(alpha: 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Subtle warm glow center
        Positioned(
          top: size.height * 0.3 + 20 * sin(angle * 0.7),
          left: size.width * 0.2,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B6B).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating particles background effect
class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _particles = List.generate(20, (_) => _Particle.random(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, radius, speed, phase;
  const _Particle(this.x, this.y, this.radius, this.speed, this.phase);

  factory _Particle.random(Random rng) => _Particle(
        rng.nextDouble(),
        rng.nextDouble(),
        rng.nextDouble() * 2 + 0.5,
        rng.nextDouble() * 0.5 + 0.2,
        rng.nextDouble() * 2 * pi,
      );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final px = p.x * size.width + sin(t * 2 * pi) * 20;
      final py = (p.y + t) % 1.0 * size.height;
      final alpha = (sin(t * pi) * 0.4).clamp(0.05, 0.35);

      final paint = Paint()
        ..color = AppTheme.primary.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

/// Glowing input field with focus animation
class _GlowingInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GlowingInputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_GlowingInputField> createState() => _GlowingInputFieldState();
}

class _GlowingInputFieldState extends State<_GlowingInputField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTheme.labelMd.copyWith(
            color: _focused
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused
                  ? AppTheme.primaryBrand.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: _focused ? 1.5 : 1,
            ),
            color: _focused
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBrand.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: AppTheme.bodyLg.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTheme.bodyMd.copyWith(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                size: 20,
                color: _focused
                    ? AppTheme.primary
                    : Colors.white.withValues(alpha: 0.35),
              ),
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: TextStyle(
                color: AppTheme.error,
                fontSize: 12,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}

/// Shimmer login button with gradient animation
class _ShimmerLoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _ShimmerLoginButton({required this.isLoading, required this.onPressed});

  @override
  State<_ShimmerLoginButton> createState() => _ShimmerLoginButtonState();
}

class _ShimmerLoginButtonState extends State<_ShimmerLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;

        return GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 3.0 * shimmerValue, 0),
                end: Alignment(1.0 + 3.0 * shimmerValue, 0),
                colors: widget.isLoading
                    ? [
                        AppTheme.primaryBrand.withValues(alpha: 0.4),
                        AppTheme.primaryBrand.withValues(alpha: 0.3),
                        AppTheme.primaryBrand.withValues(alpha: 0.4),
                      ]
                    : [
                        AppTheme.primaryBrand,
                        const Color(0xFFE53935),
                        const Color(0xFFFF5252),
                        AppTheme.primaryBrand,
                      ],
              ),
              boxShadow: widget.isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: AppTheme.primaryBrand.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Masuk',
                          style: AppTheme.bodyLg.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
