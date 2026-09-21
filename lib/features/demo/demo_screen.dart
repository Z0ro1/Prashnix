import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/user_state.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/progress_node.dart';
import '../../core/widgets/quiz_progress_bar.dart';
import '../../core/widgets/top_bar_hud.dart';
import '../../core/constants/app_constants.dart';

class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen> {
  int _quizProgress = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBarHUD(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Component Library',
                    style: AppTypography.displayBold,
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // App Card Demo
                  AppCard(
                    onTap: () {
                      ref.read(userStoreProvider.notifier).addXp(10);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Interactive Card', style: AppTypography.titleSemiBold),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          'Tap this card to add XP. Notice the subtle scale animation.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Buttons Demo
                  Text('Buttons', style: AppTypography.titleSemiBold),
                  const SizedBox(height: AppConstants.paddingSmall),
                  CustomButton(
                    text: 'Primary Action',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      ref.read(userStoreProvider.notifier).incrementStreak();
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  CustomButton(
                    text: 'Secondary Action',
                    variant: ButtonVariant.secondaryNavy,
                    onPressed: () {
                      ref.read(userStoreProvider.notifier).useHeart();
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  CustomButton(
                    text: 'Outline Button',
                    variant: ButtonVariant.outline,
                    onPressed: () {
                      ref.read(userStoreProvider.notifier).resetHearts();
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Progress Node Demo
                  Text('Progress Nodes', style: AppTypography.titleSemiBold),
                  const SizedBox(height: AppConstants.paddingSmall),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProgressNode(state: NodeState.completed),
                      ProgressNode(state: NodeState.active),
                      ProgressNode(state: NodeState.locked),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Quiz Progress Bar Demo
                  Text('Quiz Progress', style: AppTypography.titleSemiBold),
                  const SizedBox(height: AppConstants.paddingSmall),
                  QuizProgressBar(
                    totalSegments: 10,
                    currentProgress: _quizProgress,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  CustomButton(
                    text: 'Advance Progress',
                    onPressed: () {
                      setState(() {
                        _quizProgress = (_quizProgress + 1) % 11;
                      });
                    },
                  ),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
