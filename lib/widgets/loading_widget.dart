import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: size / 3,
          height: size / 3,
          decoration: BoxDecoration(
            color: color ?? AppTheme.primary,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          delay: (index * 200).ms,
          duration: 600.ms,
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeInOut,
        )
        .fade(
          delay: (index * 200).ms,
          duration: 600.ms,
          begin: 0.5,
          end: 1.0,
        );
      }),
    );
  }
}
