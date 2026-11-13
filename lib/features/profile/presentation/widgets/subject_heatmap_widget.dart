import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../skill_tree/presentation/theme/prashnix_colors.dart';
import '../../domain/models/subject_stat_model.dart';
import '../providers/subject_analytics_provider.dart';
import '../providers/settings_provider.dart';
import '../../data/repositories/analytics_repository.dart';
import '../screens/retry_sprint_screen.dart';

class SubjectHeatmapWidget extends ConsumerStatefulWidget {
  const SubjectHeatmapWidget({super.key});

  @override
  ConsumerState<SubjectHeatmapWidget> createState() => _SubjectHeatmapWidgetState();
}

class _SubjectHeatmapWidgetState extends ConsumerState<SubjectHeatmapWidget> {
  final Set<String> _expandedSubjects = {};

  void _toggleExpanded(String subjectKey) {
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      if (_expandedSubjects.contains(subjectKey)) {
        _expandedSubjects.remove(subjectKey);
      } else {
        _expandedSubjects.add(subjectKey);
      }
    });
  }

  Future<void> _startTargetedDrill(BuildContext context, SubjectStatModel subject) async {
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }

    final repo = AnalyticsRepository();
    final drillQuestions = await repo.getQuestionsForTargetedDrill(subject.rawSubjectTag, limit: 10);

    if (!context.mounted) return;

    if (drillQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${subject.formattedSubjectName} चे पुरेसे प्रश्न उपलब्ध नाहीत.'),
          backgroundColor: AppColors.stepOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RetrySprintScreen(initialQuestions: drillQuestions),
      ),
    ).then((_) {
      // Auto-refresh analytics after returning from the sprint
      ref.read(subjectAnalyticsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectAnalyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60.0),
          child: CircularProgressIndicator(color: PrashnixColors.green),
        ),
      );
    }

    final summary = state.summary;

    if (summary.totalAttempts == 0) {
      return _buildEmptyState(context, isDark, textColor, mutedColor);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // 1. Overall Diagnostic Accuracy Summary Card
        _buildOverallAccuracyCard(summary, isDark, textColor, mutedColor),
        const SizedBox(height: 20),

        // 2. Section Heading
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: PrashnixColors.green, size: 22),
                const SizedBox(width: 8),
                Text(
                  'विषयनिहाय पकड व अचूकता',
                  style: AppTextStyles.h2.copyWith(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              '${summary.subjectStats.length} विषय',
              style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. Subject Heatmap Cards List
        ...summary.subjectStats.map((subject) {
          final isExpanded = _expandedSubjects.contains(subject.rawSubjectTag);
          return _buildSubjectCard(subject, isExpanded, isDark, textColor, mutedColor);
        }),
      ],
    );
  }

  Widget _buildOverallAccuracyCard(
    OverallAnalyticsSummary summary,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final pct = summary.overallAccuracyPct;
    final Color gaugeColor = pct >= 80.0
        ? PrashnixColors.green
        : (pct >= 60.0 ? AppColors.stepOrange : PrashnixColors.red);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'एकूण तयारी अचूकता',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: AppTextStyles.h1.copyWith(
                          color: gaugeColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pct >= 80.0
                            ? 'उत्कृष्ट प्रगती 🔥'
                            : (pct >= 60.0 ? 'चांगली तयारी 👍' : 'सराव वाढवा ⚠️'),
                        style: AppTextStyles.body.copyWith(
                          color: gaugeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gaugeColor.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Icon(Icons.insights_rounded, color: gaugeColor, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accuracy Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (pct / 100.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Metric Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('सोडवले', '${summary.totalAttempts}', Icons.quiz_outlined, isDark, textColor, mutedColor),
              _buildMiniMetric('बरोबर', '${summary.totalCorrect}', Icons.check_circle_rounded, isDark, PrashnixColors.green, mutedColor),
              _buildMiniMetric('चुका', '${summary.totalIncorrect}', Icons.cancel_rounded, isDark, PrashnixColors.red, mutedColor),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    IconData icon,
    bool isDark,
    Color valColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: valColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.h3.copyWith(color: valColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: mutedColor, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    SubjectStatModel subject,
    bool isExpanded,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final Color badgeColor;
    final IconData statusIcon;

    switch (subject.masteryLevel) {
      case SubjectMasteryLevel.strong:
        badgeColor = PrashnixColors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SubjectMasteryLevel.moderate:
        badgeColor = AppColors.stepOrange;
        statusIcon = Icons.trending_up_rounded;
        break;
      case SubjectMasteryLevel.weak:
        badgeColor = PrashnixColors.red;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case SubjectMasteryLevel.calibrating:
        badgeColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: subject.isWeak
              ? PrashnixColors.red.withValues(alpha: 0.45)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: subject.isWeak ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Subject Name + Accuracy Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getSubjectIcon(subject.rawSubjectTag), color: badgeColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subject.formattedSubjectName,
                              style: AppTextStyles.h3.copyWith(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: badgeColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            subject.masteryLevel.labelMarathi,
                            style: AppTextStyles.caption.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Accuracy Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (subject.accuracyPct / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                  ),
                ),
                const SizedBox(height: 10),

                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${subject.totalAttempts} सोडवले • ${subject.incorrectCount} चुका',
                      style: AppTextStyles.caption.copyWith(color: mutedColor),
                    ),
                    Text(
                      '${subject.accuracyPct.toStringAsFixed(1)}% अचूकता',
                      style: AppTextStyles.caption.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Targeted Practice Button for Weak / Low Accuracy Subjects
                if (subject.isWeak || subject.accuracyPct < 60.0) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PrashnixColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _startTargetedDrill(context, subject),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text(
                        'या विषयाचा सराव करा (१० प्रश्न)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Subtopics Accordion Toggle (if subtopics exist)
          if (subject.subtopics.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            InkWell(
              onTap: () => _toggleExpanded(subject.rawSubjectTag),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'उपघटक विश्लेषण (${subject.subtopics.length})',
                      style: AppTextStyles.caption.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: mutedColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            if (isExpanded)
              Container(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : AppColors.surfaceLight.withValues(alpha: 0.5),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: subject.subtopics.map((subtopic) {
                    final subColor = subtopic.accuracyPct >= 80.0
                        ? PrashnixColors.green
                        : (subtopic.accuracyPct >= 60.0 ? AppColors.stepOrange : PrashnixColors.red);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: subColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtopic.subtopicName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${subtopic.accuracyPct.toStringAsFixed(0)}% (${subtopic.correctCount}/${subtopic.totalAttempts})',
                            style: AppTextStyles.caption.copyWith(
                              color: subColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ],
      ),
    ).animate().fade().slideY(begin: 0.05);
  }

  IconData _getSubjectIcon(String rawSubject) {
    final lower = rawSubject.toLowerCase();
    if (lower.contains('math') || lower.contains('गणित') || lower.contains('अंकगणित')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('reasoning') || lower.contains('बुद्धिमत्ता')) {
      return Icons.psychology_rounded;
    }
    if (lower.contains('marathi') || lower.contains('मराठी') || lower.contains('व्याकरण')) {
      return Icons.menu_book_rounded;
    }
    if (lower.contains('history') || lower.contains('इतिहास')) {
      return Icons.history_edu_rounded;
    }
    if (lower.contains('geography') || lower.contains('भूगोल')) {
      return Icons.public_rounded;
    }
    return Icons.school_rounded;
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PrashnixColors.green.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.analytics_outlined, color: PrashnixColors.green, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'अजून पुरेसा डेटा नाही',
              style: AppTextStyles.h2.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'दैनिक धडे, टेस्ट किंवा चुकांचा सराव करा. तुमचे मजबूत व कच्चे विषय येथे आपोआप वर्गीकृत होतील!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: mutedColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

