import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/core/theme/app_theme.dart';

class ResponseLoadingSpinner extends StatefulWidget {
  const ResponseLoadingSpinner({super.key});

  @override
  State<ResponseLoadingSpinner> createState() => _ResponseLoadingSpinnerState();
}

class _ResponseLoadingSpinnerState extends State<ResponseLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating gradient sweep ring
            Transform.rotate(
              angle: _anim.value * 2 * math.pi,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.0),
                      AppTheme.primary.withValues(alpha: 0.35),
                      AppTheme.primary,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF161922),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            // Inner icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
