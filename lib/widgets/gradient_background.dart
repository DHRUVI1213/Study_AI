import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ??
              [
                AppColors.background,
                const Color(0xFF111827),
                AppColors.background,
              ],
        ),
      ),
      child: child,
    );
  }
}

class GradientOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double top;
  final double left;

  const GradientOrb({
    super.key,
    required this.color,
    this.size = 200,
    this.top = -50,
    this.left = -50,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.25), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
