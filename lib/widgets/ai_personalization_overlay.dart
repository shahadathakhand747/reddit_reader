import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Full-screen modal overlay for AI personalization
class AiPersonalizationOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const AiPersonalizationOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<AiPersonalizationOverlay> createState() =>
      _AiPersonalizationOverlayState();
}

class _AiPersonalizationOverlayState extends State<AiPersonalizationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Complete after delay
    Future.delayed(AnimationDurations.aiDelay, () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.accent.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🧠',
                    style: TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.largeSpacing),
            Text(
              AppStrings.aiAnalyzing,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacing),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show AI personalization overlay
Future<void> showAiPersonalizationOverlay(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => const AiPersonalizationOverlay(
      onComplete: _doNothing,
    ),
  ).timeout(AnimationDurations.aiDelay, onTimeout: () {});

  // Ignore return value, callback handles completion
}

void _doNothing() {}
