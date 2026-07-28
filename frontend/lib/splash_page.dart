import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'api_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    // Logo entrance animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // Continuous pulse & rotation animation (drives background tech grid & logo glow)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text entrance animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Start animation sequence & check authentication
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _textController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    try {
      final token = await _apiService.getToken();
      if (mounted) {
        if (token != null && token.isNotEmpty) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Stack(
        children: [
          // 1. Ambient Gradient Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseVal = _pulseController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.12),
                    radius: 1.0 + (pulseVal * 0.2),
                    colors: [
                      Color.lerp(
                        const Color(0xFF380B15),
                        const Color(0xFF500F1E),
                        pulseVal,
                      )!,
                      const Color(0xFF140A10),
                      const Color(0xFF0D0E15),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              );
            },
          ),

          // 2. Ultra Lightweight Custom Animated Cyber Tech Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _CyberGridPainter(
                repaint: _pulseController,
                progress: _pulseController,
              ),
            ),
          ),

          // 3. Main Splash Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Animated Logo with glowing pulse rings
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _pulseController]),
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulsing glow ring
                            Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD32F2F)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF800020)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Rotating tech circle border
                            Transform.rotate(
                              angle: _pulseController.value * 2 * math.pi,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF4D4D)
                                        .withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // App Logo Image
                            Container(
                              width: 130,
                              height: 130,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.45),
                                border: Border.all(
                                  color: const Color(0xFFD32F2F)
                                      .withValues(alpha: 0.65),
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.business_rounded,
                                    size: 60,
                                    color: Color(0xFFD32F2F),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Animated App Title & Subtitle
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        // App Name Header
                        const Text(
                          'SOBM',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0xFFD32F2F),
                                blurRadius: 16,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle Tagline Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Smart Office Building Management',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF8A8A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ultra lightweight CustomPainter for cyber grid lines & scanning beam effect
class _CyberGridPainter extends CustomPainter {
  final Animation<double> progress;

  _CyberGridPainter({
    required Listenable repaint,
    required this.progress,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;

    final linePaint = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    final nodePaint = Paint()
      ..color = const Color(0xFFFF4D4D).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    const double step = 60.0;

    // Vertical grid lines & glowing nodes
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Horizontal grid lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Floating circuit nodes (calculated math points, 0 allocations)
    for (int i = 1; i <= 6; i++) {
      final double nx = (size.width * 0.15 * i + math.sin(t * math.pi + i) * 20) % size.width;
      final double ny = (size.height * 0.12 * i + math.cos(t * math.pi + i) * 25) % size.height;
      final double radius = 2.0 + math.sin(t * math.pi + i).abs() * 2.0;

      canvas.drawCircle(Offset(nx, ny), radius, nodePaint);
    }

    // Scanning horizontal laser line
    final double scanY = (t * size.height * 1.2) % size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFD32F2F).withValues(alpha: 0.18),
          const Color(0xFFFF4D4D).withValues(alpha: 0.35),
          const Color(0xFFD32F2F).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter oldDelegate) => true;
}
