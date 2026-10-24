import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      ref.read(timedExamProvider.notifier).startExam();
    });
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text('Submit Exam?', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          content: Text("Are you sure you want to submit your test early?", style: AppTextStyles.body.copyWith(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                ref.read(timedExamProvider.notifier).submitExam();
              },
              child: const Text('SUBMIT', style: TextStyle(color: AppColors.primaryMint, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timedExamProvider);
    final notifier = ref.read(timedExamProvider.notifier);

    // Watch for submission
    ref.listen<TimedExamState>(timedExamProvider, (previous, next) {
      if (next.status == TimedExamStatus.autoSubmitted || next.status == TimedExamStatus.manuallySubmitted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TestAnalyticsScreen()),
        );
      }
    });

    final question = state.currentQuestion;
    if (question == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryMint)),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F1115),
      endDrawer: Drawer(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: const Color(0xFF0F1115).withValues(alpha: 0.8),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Question Navigator', style: AppTextStyles.h3.copyWith(color: Colors.white)),
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
                        
                        Color bgColor = Colors.white.withValues(alpha: 0.05);
                        Color borderColor = Colors.white.withValues(alpha: 0.1);
                        Color textColor = Colors.white54;
                        
                        if (isAnswered) {
                          bgColor = AppColors.primaryMint.withValues(alpha: 0.2);
                          borderColor = AppColors.primaryMint.withValues(alpha: 0.5);
                          textColor = AppColors.primaryMint;
                        }
                        if (isCurrent) {
                          bgColor = AppColors.canaryYellow.withValues(alpha: 0.2);
                          borderColor = AppColors.canaryYellow;
                          textColor = AppColors.canaryYellow;
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
                              border: Border.all(color: borderColor),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ).animate().fade(delay: (index * 10).ms);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMint,
                          foregroundColor: const Color(0xFF0F1115),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // close drawer
                          _confirmSubmit();
                        },
                        child: const Text('SUBMIT TEST', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                height: 400,
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
                // Header Glass Container
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: _confirmSubmit, // Same action as quit/submit
                          ),
                          const Spacer(),
                          // Timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: state.isTimeCritical 
                                  ? AppColors.error.withValues(alpha: 0.2) 
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: state.isTimeCritical ? AppColors.error : Colors.white.withValues(alpha: 0.2)),
                              boxShadow: state.isTimeCritical ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 10)] : null,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_rounded, size: 16, color: state.isTimeCritical ? AppColors.error : Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  state.timeFormatted,
                                  style: TextStyle(
                                    color: state.isTimeCritical ? AppColors.error : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(target: state.isTimeCritical ? 1 : 0).shake(hz: 4),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
                            onPressed: () {
                              _scaffoldKey.currentState?.openEndDrawer();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Progress Bar
                LinearProgressIndicator(
                  value: state.answeredCount / state.questions.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  color: AppColors.primaryMint,
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
                            Text('Q ${state.currentIndex + 1}', style: AppTextStyles.h3.copyWith(color: AppColors.canaryYellow)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Text(question.subjectTag, style: AppTextStyles.label.copyWith(color: Colors.white70)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          question.questionText,
                          style: AppTextStyles.h2.copyWith(height: 1.4, color: Colors.white),
                        ).animate(key: ValueKey(question.id)).fade().slideY(begin: 0.1),
                        const SizedBox(height: 48),
    
                        ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                          final int index = entry.key;
                          final String label = entry.value;
                          
                          String text;
                          if (label == 'A') {
                            text = question.optionA;
                          } else if (label == 'B') {
                            text = question.optionB;
                          } else if (label == 'C') {
                            text = question.optionC;
                          } else {
                            text = question.optionD;
                          }
    
                          final isSelected = state.answers[state.currentIndex] == label;
    
                          return InteractiveOptionPill(
                            label: label,
                            text: text,
                            state: isSelected ? OptionState.selected : OptionState.defaultState,
                            onTap: () {
                              notifier.selectOption(label);
                              // Auto advance after short delay
                              Future.delayed(const Duration(milliseconds: 400), () {
                                if (mounted && state.currentIndex < state.questions.length - 1) {
                                  notifier.nextQuestion();
                                }
                              });
                            },
                          ).animate(key: ValueKey('${question.id}_$label'))
                           .fade(delay: (200 + (index * 100)).ms)
                           .slideY(begin: 0.2, delay: (200 + (index * 100)).ms);
                        }),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Nav Glass Container
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: state.currentIndex > 0 ? notifier.prevQuestion : null,
                            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: state.currentIndex > 0 ? Colors.white70 : Colors.white30),
                            label: Text('Prev', style: TextStyle(color: state.currentIndex > 0 ? Colors.white70 : Colors.white30)),
                          ),
                          TextButton(
                            onPressed: _confirmSubmit,
                            child: const Text('SUBMIT', style: TextStyle(color: AppColors.primaryMint, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                          TextButton.icon(
                            onPressed: state.currentIndex < state.questions.length - 1 ? notifier.nextQuestion : null,
                            label: Text('Next', style: TextStyle(color: state.currentIndex < state.questions.length - 1 ? Colors.white70 : Colors.white30)),
                            icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: state.currentIndex < state.questions.length - 1 ? Colors.white70 : Colors.white30),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
