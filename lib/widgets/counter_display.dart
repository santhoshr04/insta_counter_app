import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta_counter_app/core/utils/count_format.dart';

/// Large split-flap inspired follower readout with digit animation.
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({
    super.key,
    required this.value,
  });

  final double value;

  String _format() => formatFollowerCount(value);

  @override
  Widget build(BuildContext context) {
    final formatted = _format();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        formatted,
        key: ValueKey<String>(formatted),
        textAlign: TextAlign.center,
        style: GoogleFonts.orbitron(
          fontSize: 52,
          height: 1.05,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [
                Color(0xFFE8E8F0),
                Color(0xFFB8B8CC),
              ],
            ).createShader(const Rect.fromLTWH(0, 0, 400, 120)),
        ),
      ),
    );
  }
}
