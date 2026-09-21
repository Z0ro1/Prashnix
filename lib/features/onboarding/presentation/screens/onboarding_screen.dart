import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/avatar_grid_step.dart';
import '../widgets/district_picker_step.dart';
import '../widgets/username_input_step.dart';

import '../../../../core/widgets/root_navigator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RootNavigator()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    // Sync PageView with Provider State
    if (_pageController.hasClients) {
      final targetPage = state.currentStep.toDouble();
      if (_pageController.page != targetPage) {
        _pageController.animateToPage(
          state.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    final totalSteps = 3;
    final progress = (state.currentStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar & Step Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  if (state.currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMint),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Placeholder for alignment
                ],
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable manual swipe
                children: const [
                  UsernameInputStep(),
                  AvatarGridStep(),
                  DistrictPickerStep(),
                ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
