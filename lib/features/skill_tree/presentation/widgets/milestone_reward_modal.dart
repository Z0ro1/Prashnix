import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/state/user_state.dart';
import '../providers/skill_tree_provider.dart';

class MilestoneRewardModal extends ConsumerStatefulWidget {
  final SkillNode node;

  const MilestoneRewardModal({super.key, required this.node});

  static void show(BuildContext context, SkillNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MilestoneRewardModal(node: node),
    );
  }

  @override
  ConsumerState<MilestoneRewardModal> createState() => _MilestoneRewardModalState();
}

class _MilestoneRewardModalState extends ConsumerState<MilestoneRewardModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openChest() {
    setState(() {
      _isOpened = true;
    });
    // Add XP reward
    ref.read(userStoreProvider.notifier).addXp(100);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115).withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 32),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                _isOpened ? '💎' : '🎁',
                style: const TextStyle(fontSize: 100),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isOpened ? 'Awesome! +100 XP' : 'Milestone Reached!',
              style: AppTextStyles.h2.copyWith(
                color: _isOpened ? AppColors.primaryMint : const Color(0xFFFFC107),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isOpened 
                  ? 'You earned bonus XP for your hard work.' 
                  : 'Open the chest to reveal your reward.',
              style: AppTextStyles.body.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_isOpened)
              CustomButton(
                text: 'Open Chest',
                variant: ButtonVariant.primaryMint,
                onPressed: _openChest,
              )
            else
              CustomButton(
                text: 'Continue',
                variant: ButtonVariant.primaryMint,
                onPressed: () {
                  Navigator.of(context).pop();
                  // Complete node in provider
                  ref.read(skillTreeProvider.notifier).completeLesson(widget.node.id);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
