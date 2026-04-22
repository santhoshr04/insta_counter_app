import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';

/// Simple shimmer bar for mock scan loading (bonus).
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.height = 14, this.borderRadius = 8});

  final double height;
  final double borderRadius;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = rect.width * 2 * (_c.value - 0.5);
            return LinearGradient(
              colors: [
                AppTheme.outline,
                Colors.white.withValues(alpha: 0.12),
                AppTheme.outline,
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: Alignment(dx, 0),
              end: Alignment(dx + 1, 0),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
