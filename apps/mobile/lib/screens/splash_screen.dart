import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() loadData;
  final VoidCallback onReady;

  const SplashScreen({
    super.key,
    required this.loadData,
    required this.onReady,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartbeatController;

  @override
  void initState() {
    super.initState();

    // Heartbeat: ~1.2s cycle, repeats
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _startSequence();
  }

  Future<void> _startSequence() async {
    await widget.loadData();
    // Minimum splash duration
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) widget.onReady();
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  /// Heartbeat curve: bump-bump...pause...bump-bump...pause
  double _heartbeatScale(double t) {
    // First beat: 0.00 - 0.15
    if (t < 0.15) {
      final p = t / 0.15;
      return 1.0 + 0.08 * _bump(p);
    }
    // Small pause: 0.15 - 0.25
    if (t < 0.25) return 1.0;
    // Second beat (slightly smaller): 0.25 - 0.40
    if (t < 0.40) {
      final p = (t - 0.25) / 0.15;
      return 1.0 + 0.05 * _bump(p);
    }
    // Long pause: 0.40 - 1.0
    return 1.0;
  }

  /// Smooth bump: 0→1→0
  double _bump(double t) {
    return (t < 0.5)
        ? (2 * t * t)
        : (1 - 2 * (1 - t) * (1 - t));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _heartbeatController,
          builder: (context, child) {
            final scale = _heartbeatScale(_heartbeatController.value);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Image.asset(
              'assets/images/meb-logo-icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
