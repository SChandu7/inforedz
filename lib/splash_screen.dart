import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dropCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _textCtrl;
  late AnimationController _letterCtrl;
  late AnimationController _colorCtrl;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _ripple;
  late Animation<double> _fade;
  late Animation<double> _pulse;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _letterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropCtrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _ripple = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(_fadeCtrl);
    _pulse = Tween(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _textFade = Tween(begin: 0.0, end: 1.0).animate(_textCtrl);
    _textSlide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _dropCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _fadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();
    _letterCtrl.forward(); // ← start letter animation
    await Future.delayed(const Duration(milliseconds: 1000));
    _colorCtrl.forward(); // ← color change after all letters visible
    await Future.delayed(const Duration(milliseconds: 1700));
    _navigate();
  }

  Future<void> _navigate() async {
    await AuthState.loadFromPrefs();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            AuthState.isLoggedIn ? const HomeScreen() : const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _letterCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFF4F4),
              Color(0xFFFFE8E8),
              Color(0xFFFFD6D6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── decorative red circle top right ──────────────
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rose.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rose.withOpacity(0.05),
                ),
              ),
            ),

            // ── decorative circle bottom left ─────────────────
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rose.withOpacity(0.07),
                ),
              ),
            ),

            // ── medical cross pattern ─────────────────────────
            ..._buildBgPattern(),

            // ── red top accent line ───────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: AppColors.rose),
            ),

            // ── heartbeat line decoration ─────────────────────
            Positioned(
              top: size.height * 0.18,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(
                  size: Size(size.width, 40),
                  painter: _HeartbeatPainter(),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.22,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(
                  size: Size(size.width, 40),
                  painter: _HeartbeatPainter(),
                ),
              ),
            ),

            // ── center content ────────────────────────────────
            Positioned(
              top:
                  MediaQuery.of(context).size.height *
                  0.28, // ← between top and middle
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 0),
                  // logo with drop animation
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ripple rings
                        AnimatedBuilder(
                          animation: _ripple,
                          builder: (_, __) => Stack(
                            alignment: Alignment.center,
                            children: [1.0, 0.7, 0.4].asMap().entries.map((e) {
                              final delay = e.key * 0.15;
                              final prog =
                                  ((_ripple.value - delay) / (1 - delay)).clamp(
                                    0.0,
                                    1.0,
                                  );
                              return Container(
                                width: 70 + prog * 90,
                                height: 70 + prog * 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.rose.withOpacity(
                                      (1 - prog) * 0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // logo drop
                        AnimatedBuilder(
                          animation: Listenable.merge([_dropCtrl, _pulseCtrl]),
                          builder: (_, __) => FadeTransition(
                            opacity: _logoFade,
                            child: Transform.scale(
                              scale: _logoScale.value * _pulse.value,
                              child: _buildBloodDrop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 1),

                  // ── letter by letter app name ─────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([_letterCtrl, _colorCtrl]),
                    builder: (_, __) {
                      const fullText = 'InfoReDZ';
                      const splitAt = 4; // 'Info' = 4 chars, 'ReDZ' = 4 chars
                      final totalChars = fullText.length;
                      final visibleCount = (_letterCtrl.value * totalChars)
                          .ceil()
                          .clamp(0, totalChars);
                      final colorDone = _colorCtrl.value == 1.0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(visibleCount, (i) {
                          final char = fullText[i];
                          final isRed = i >= splitAt;

                          // before color anim: all chars are inkDark
                          // after color anim: first 4 = inkDark, last 4 = rose
                          final color = colorDone
                              ? (isRed ? AppColors.rose : AppColors.inkDark)
                              : AppColors.inkDark;

                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: color,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.0,
                            ),
                            child: Text(char),
                          );
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // tagline fade in
                  FadeTransition(
                    opacity: _textFade,
                    child: const Text(
                      'Every drop counts. Every life matters.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── bottom pills ──────────────────────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    // blood type badges row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-']
                              .map(
                                (g) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.rose.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.rose.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    g,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── bottom red accent ─────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 3, color: AppColors.rose),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodDrop() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.rose, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x55CC0000), blurRadius: 24, spreadRadius: 4),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/icon.jpeg', fit: BoxFit.cover),
      ),
    );
  }

  List<Widget> _buildBgPattern() {
    final positions = [
      const Offset(30, 60),
      const Offset(320, 80),
      const Offset(60, 500),
      const Offset(300, 480),
      const Offset(180, 120),
      const Offset(200, 600),
    ];
    return positions
        .map(
          (p) => Positioned(
            left: p.dx,
            top: p.dy,
            child: Opacity(
              opacity: 0.04,
              child: Icon(Icons.add_rounded, size: 40, color: AppColors.rose),
            ),
          ),
        )
        .toList();
  }

  Widget _statPill(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rose
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height / 2;

    path.moveTo(0, h);
    path.lineTo(w * 0.15, h);
    path.lineTo(w * 0.22, h - 14);
    path.lineTo(w * 0.27, h + 14);
    path.lineTo(w * 0.32, h - 22);
    path.lineTo(w * 0.38, h + 22);
    path.lineTo(w * 0.43, h - 10);
    path.lineTo(w * 0.48, h);
    path.lineTo(w * 0.63, h);
    path.lineTo(w * 0.70, h - 14);
    path.lineTo(w * 0.75, h + 14);
    path.lineTo(w * 0.80, h - 22);
    path.lineTo(w * 0.86, h + 22);
    path.lineTo(w * 0.91, h - 10);
    path.lineTo(w * 0.96, h);
    path.lineTo(w, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
