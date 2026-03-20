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

  late Animation<double> _dropY;
  late Animation<double> _dropScale;
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

    _dropY = Tween(
      begin: -80.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));
    _dropScale = Tween(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.elasticOut));
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
    await Future.delayed(const Duration(milliseconds: 600));
    _fadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF0F0), Color(0xFFFFE4E4)],
          ),
        ),
        child: Stack(
          children: [
            // Background medical cross pattern
            ..._buildBgPattern(),
            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated drop + ripple
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple rings
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
                                width: 60 + prog * 80,
                                height: 60 + prog * 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.rose.withOpacity(
                                      (1 - prog) * 0.25,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Drop
                        AnimatedBuilder(
                          animation: Listenable.merge([_dropCtrl, _pulseCtrl]),
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, _dropY.value),
                            child: Transform.scale(
                              scale: _dropScale.value * _pulse.value,
                              child: _buildBloodDrop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // App name
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Info',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.inkDark,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                TextSpan(
                                  text: 'redz',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.rose,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Every drop counts. Every life matters.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom tagline
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statPill('🩸', 'Donate Blood'),
                        const SizedBox(width: 12),
                        _statPill('🏥', 'Find Banks'),
                        const SizedBox(width: 12),
                        _statPill('❤️', 'Save Lives'),
                      ],
                    ),
                  ],
                ),
              ),
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
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFF4444), AppColors.rose, AppColors.roseDark],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x55CC0000), blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: const Icon(
        Icons.water_drop_rounded,
        color: Colors.white,
        size: 38,
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
