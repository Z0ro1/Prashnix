import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/onboarding_provider.dart';

class UsernameInputStep extends ConsumerWidget {
  const UsernameInputStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    Color getStatusColor() {
      switch (state.usernameStatus) {
        case UsernameStatus.available:
          return AppColors.primaryMint;
        case UsernameStatus.taken:
        case UsernameStatus.invalidFormat:
        case UsernameStatus.error:
          return AppColors.accentRed;
        default:
          return Colors.white.withValues(alpha: 0.1);
      }
    }

    String getStatusMessage() {
      switch (state.usernameStatus) {
        case UsernameStatus.checking:
          return 'Checking availability...';
        case UsernameStatus.available:
          return 'Username is available!';
        case UsernameStatus.taken:
          return 'Username is already taken.';
        case UsernameStatus.invalidFormat:
          return '3-15 chars, lowercase, numbers, underscores only.';
        case UsernameStatus.error:
          return 'Network error. Please try again.';
        default:
          return '';
      }
    }

    Widget getStatusIcon() {
      switch (state.usernameStatus) {
        case UsernameStatus.checking:
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMint),
          );
        case UsernameStatus.available:
          return const Icon(Icons.check_circle, color: AppColors.primaryMint, size: 20);
        case UsernameStatus.taken:
        case UsernameStatus.invalidFormat:
        case UsernameStatus.error:
          return const Icon(Icons.cancel, color: AppColors.accentRed, size: 20);
        default:
          return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose your Candidate ID',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This will be your unique leaderboard name.',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: getStatusColor(), width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '@',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryMint),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'username',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                    onChanged: notifier.onUsernameChanged,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey(state.usernameStatus),
                    child: getStatusIcon(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              getStatusMessage(),
              key: ValueKey(state.usernameStatus),
              style: AppTextStyles.label.copyWith(color: getStatusColor()),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
