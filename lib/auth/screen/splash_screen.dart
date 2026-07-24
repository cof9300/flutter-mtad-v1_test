import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/auth/screen/standby_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color _splashColor = Color(0xFF227EFF);

  late final AnimationController _rippleController;
  late final AnimationController _logoController;

  late final Animation<double> _rippleScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _rippleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _rippleController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const StandbyScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RipplePainter(
                    color: _splashColor,
                    progress: _rippleScale.value,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, _) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Center(
                    child: Image.asset(
                      'assets/icons/splash_logo.png',
                      width: 340,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Color color;
  final double progress;

  _RipplePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        (size.width > size.height ? size.width : size.height) * 0.75;

    final easedProgress = Curves.easeInOut.transform(progress);
    final radius = maxRadius * easedProgress;

    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.color != color;
}
