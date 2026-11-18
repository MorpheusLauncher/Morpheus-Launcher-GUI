import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:morpheus_launcher_gui/globals.dart';

class GlassMorphism extends StatelessWidget {
  final double blur;
  final double opacity;
  final double radius;
  final Color? color;
  final Widget child;

  const GlassMorphism({
    super.key,
    required this.blur,
    required this.opacity,
    required this.radius,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        // Avoid compositing the filtered backdrop over the original content when an ancestor renders into a temporary layer.
        blendMode: BlendMode.src,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (color ?? ColorUtils.dynamicBackgroundColor).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
