import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/avatar_grid_step.dart';
import '../widgets/district_picker_step.dart';
import '../widgets/username_input_step.dart';

import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _previousStep = 0;

  void _navigateToHome() {
    context.go('/home');
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return const UsernameInputStep(key: ValueKey(0));
      case 1:
        return const AvatarGridStep(key: ValueKey(1));
      case 2:
        return const DistrictPickerStep(key: ValueKey(2));
      default:
        return const SizedBox.shrink(key: ValueKey(-1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    // Determine direction for the parallax animation
    final isForward = state.currentStep >= _previousStep;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _previousStep = state.currentStep;
      }
    });

    final totalSteps = 3;
    final progress = (state.currentStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: 50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
              height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMint.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar & Step Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      if (state.currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                          onPressed: state.isSubmitting ? null : notifier.previousStep,
                        )
                      else
                        const SizedBox(width: 48), // Placeholder for alignment
                      
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'STEP ${state.currentStep + 1}/$totalSteps',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: progress),
                                  duration: 300.ms,
                                  curve: Curves.easeOutQuint,
                                  builder: (context, value, _) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryMint,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.5), blurRadius: 10)],
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Placeholder for alignment
                    ],
                  ),
                ),
                
                // Main Content Area (Parallax Animation)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutQuint,
                    switchOutCurve: Curves.easeInQuint,
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final childKey = child.key as ValueKey<int>?;
                      final isIncoming = childKey?.value == state.currentStep;
    
                      // Determine offset direction based on forward/backward navigation
                      Offset beginOffset;
                      if (isForward) {
                        beginOffset = isIncoming ? const Offset(0.15, 0.0) : const Offset(-0.15, 0.0);
                      } else {
                        beginOffset = isIncoming ? const Offset(-0.15, 0.0) : const Offset(0.15, 0.0);
                      }
    
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: beginOffset,
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStep(state.currentStep),
                  ),
                ),
                
                // Bottom Action Bar
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: CustomButton(
                    text: state.isSubmitting 
                        ? 'Setting up Profile...' 
                        : (state.currentStep == 2 ? 'Lock In Profile ➔' : 'Continue'),
                    onPressed: state.isCurrentStepValid && !state.isSubmitting
                        ? () async {
                            if (state.currentStep == 2) {
                              final success = await notifier.submitProfile();
                              if (success && mounted) {
                                _navigateToHome();
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to complete onboarding. Please try again.')),
                                );
                              }
                            } else {
                              notifier.nextStep();
                              FocusScope.of(context).unfocus(); // Close keyboard
                            }
                          }
                        : null,
                    variant: ButtonVariant.primaryMint,
                    isLoading: state.isSubmitting,
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
