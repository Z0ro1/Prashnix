import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/onboarding_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AvatarGridStep extends ConsumerWidget {
  const AvatarGridStep({super.key});

  final List<String> _avatars = const [
    'Nami.jpg', 'brook.jpg', 'chopper.jpg', 
    'frenky.jpg', 'luffy.jpg', 'robin.jpg', 
    'sanji.jpg', 'ussop.jpg', 'zoro.jpg',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Select your Avatar',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This is how others will see you on the leaderboard.',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatarId = _avatars[index];
                final isSelected = state.selectedAvatarId == avatarId;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.setAvatar(avatarId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    transform: Matrix4.diagonal3Values(
                      isSelected ? 1.05 : 1.0, 
                      isSelected ? 1.05 : 1.0, 
                      1.0
                    ),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryMint : Colors.white.withValues(alpha: 0.2),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryMint.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                      image: DecorationImage(
                        image: AssetImage('assets/avatars/$avatarId'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ).animate(delay: (index * 40).ms).scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}
