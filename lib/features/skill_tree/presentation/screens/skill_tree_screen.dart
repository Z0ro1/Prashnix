import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../gamification/presentation/widgets/top_bar_hud.dart';
import '../providers/skill_tree_provider.dart';

import '../widgets/milestone_reward_modal.dart';
import '../widgets/skill_tree_node_builder.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
import '../../../gamification/presentation/widgets/heart_refill_modal_sheet.dart';
import '../../../quiz/presentation/providers/quiz_provider.dart';
import '../../../quiz/presentation/screens/quiz_screen.dart';

class SkillTreeScreen extends ConsumerStatefulWidget {
  const SkillTreeScreen({super.key});

  @override
  ConsumerState<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends ConsumerState<SkillTreeScreen> {
  String? _selectedNodeId;

  // Convert hex color to Color object
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }


  @override
  Widget build(BuildContext context) {
    final units = ref.watch(skillTreeProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: const TopBarHUD(),
      body: GestureDetector(
        onTap: () {
          // Dismiss tooltip if tapped outside
          if (_selectedNodeId != null) {
            setState(() {
              _selectedNodeId = null;
            });
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            for (int i = 0; i < units.length; i++)
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _hexToColor(units[i].colorHex).withValues(alpha: 0.15),
                        if (i < units.length - 1)
                          _hexToColor(units[i + 1].colorHex).withValues(alpha: 0.15)
                        else
                          AppColors.surfaceLight,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildUnitHeader(units[i]),
                      for (int index = 0; index < units[i].nodes.length; index++)
                        SkillTreeNodeBuilder(
                          node: units[i].nodes[index],
                          index: index,
                          isLastNode: index == units[i].nodes.length - 1,
                          unitColor: _hexToColor(units[i].colorHex),
                          isSelected: _selectedNodeId == units[i].nodes[index].id,
                          onTap: () {
                            final hasEnoughHearts = ref.read(heartEconomyProvider.notifier).attemptLessonLaunch();
                            if (hasEnoughHearts) {
                              ref.read(quizProvider.notifier).loadQuestionsForNode(units[i].nodes[index].id);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const QuizScreen()),
                              );
                            } else {
                              HeartRefillModalSheet.show(context);
                            }
                          },
                          onStart: () {},
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitHeader(SkillUnit unit) {
    final unitColor = _hexToColor(unit.colorHex);
    
    // Create a darker shade for the 3D shadow extrusion
    final hsl = HSLColor.fromColor(unitColor);
    final darkColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: darkColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), // The 3D height
        decoration: BoxDecoration(
          color: unitColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECTION ${unit.id}, UNIT ${unit.id}', // Currently using id for both
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unit.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
