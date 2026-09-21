import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../quiz/presentation/widgets/interactive_option_pill.dart';
import '../providers/timed_exam_provider.dart';
import 'test_analytics_screen.dart';

class TimedExamScreen extends ConsumerStatefulWidget {
  const TimedExamScreen({super.key});

  @override
  ConsumerState<TimedExamScreen> createState() => _TimedExamScreenState();
}

class _TimedExamScreenState extends ConsumerState<TimedExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timedExamNotifierProvider.notifier).startExam();
    });
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: const Text("Are you sure you want to submit your test early?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              ref.read(timedExamNotifierProvider.notifier).submitExam();
            },
            child: const Text('SUBMIT', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timedExamNotifierProvider);
    final notifier = ref.read(timedExamNotifierProvider.notifier);

    // Watch for submission
    ref.listen<TimedExamState>(timedExamNotifierProvider, (previous, next) {
      if (next.status == TimedExamStatus.autoSubmitted || next.status == TimedExamStatus.manuallySubmitted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TestAnalyticsScreen()),
        );
      }
    });

    final question = state.currentQuestion;
    if (question == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Question Navigator', style: AppTextStyles.h3),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: state.questions.length,
                  itemBuilder: (context, index) {
                    final isAnswered = state.answers.containsKey(index);
                    final isCurrent = index == state.currentIndex;
                    
                    Color bgColor = AppColors.surfaceLighter;
                    Color textColor = AppColors.textPrimary;
                    
                    if (isAnswered) {
                      bgColor = AppColors.success.withValues(alpha: 0.2);
                      textColor = AppColors.success;
                    }
                    if (isCurrent) {
                      bgColor = AppColors.primary;
                      textColor = Colors.white;
                    }

                    return GestureDetector(
                      onTap: () {
                        notifier.jumpToQuestion(index);
                        Navigator.pop(context); // Close drawer
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCurrent ? AppColors.primary : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(context); // close drawer
                    _confirmSubmit();
                  },
                  child: const Text('SUBMIT TEST', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _confirmSubmit, // Same action as quit/submit
                  ),
                  const Spacer(),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: state.isTimeCritical ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: state.isTimeCritical ? AppColors.error : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: state.isTimeCritical ? AppColors.error : AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          state.timeFormatted,
                          style: TextStyle(
                            color: state.isTimeCritical ? AppColors.error : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                ],
              ),
            ),
            
            // Progress Bar
            LinearProgressIndicator(
              value: state.answeredCount / state.questions.length,
              backgroundColor: AppColors.surfaceLighter,
              color: AppColors.success,
              minHeight: 4,
            ),

            // Question Surface
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Q ${state.currentIndex + 1}', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4)),
                          child: Text(question.subjectTag, style: AppTextStyles.label),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      question.questionText,
                      style: AppTextStyles.h2.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 48),

                    ...['A', 'B', 'C', 'D'].map((label) {
                      String text;
                      if (label == 'A') text = question.optionA;
                      else if (label == 'B') text = question.optionB;
                      else if (label == 'C') text = question.optionC;
                      else text = question.optionD;

                      final isSelected = state.answers[state.currentIndex] == label;

                      return InteractiveOptionPill(
                        label: label,
                        text: text,
                        state: isSelected ? OptionState.selected : OptionState.defaultState,
                        onTap: () {
                          notifier.selectOption(label);
                          // Auto advance after short delay
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted && state.currentIndex < state.questions.length - 1) {
                              notifier.nextQuestion();
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Bottom Nav
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: state.currentIndex > 0 ? notifier.prevQuestion : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('Prev'),
                  ),
                  TextButton(
                    onPressed: _confirmSubmit,
                    child: const Text('SUBMIT', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  TextButton.icon(
                    onPressed: state.currentIndex < state.questions.length - 1 ? notifier.nextQuestion : null,
                    label: const Text('Next'),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
