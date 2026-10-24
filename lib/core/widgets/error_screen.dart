import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'custom_button.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String recommendation;
  final VoidCallback onRetry;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;

  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    required this.recommendation,
    required this.onRetry,
    this.onSecondaryAction,
    this.secondaryActionText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: 200,
            left: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Error Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.error,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    title,
                    style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Message
                  Text(
                    message,
                    style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Recommendation Box
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.skyBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                recommendation,
                                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Actions
                  CustomButton(
                    text: "TRY AGAIN",
                    variant: ButtonVariant.primaryMint,
                    onPressed: onRetry,
                  ),
                  if (onSecondaryAction != null && secondaryActionText != null) ...[
                    const SizedBox(height: 12),
                    CustomButton(
                      text: secondaryActionText!,
                      variant: ButtonVariant.outline,
                      onPressed: onSecondaryAction,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
