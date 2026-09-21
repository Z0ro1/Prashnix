import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: 80,
                    color: AppColors.accentAmber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gold League',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Top 10 advance to the next league',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  itemCount: 15,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rank = index + 1;
                    final isMe = rank == 4;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: isMe
                          ? BoxDecoration(
                              color: AppColors.primaryMint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            )
                          : null,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              rank.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: rank <= 3 ? AppColors.accentAmber : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: isMe ? AppColors.primaryMint : Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              color: isMe ? Colors.white : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              isMe ? 'You' : 'User $rank',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                                color: isMe ? AppColors.primaryMint : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${(15 - index) * 120} XP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
