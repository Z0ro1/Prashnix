import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/navigation/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  String _statusText = 'सत्र सुरू करत आहे...';

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _startInitializationFlow();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startInitializationFlow() async {
    // Dynamic status text updates
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _statusText = 'अभ्यासक्रम लोड होत आहे...');

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _statusText = 'सज्ज व्हा! खाकीचं स्वप्न...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final session = SupabaseConfig.client.auth.currentSession;
    final routerNotifier = ref.read(routerNotifierProvider);

    // If deep link password recovery was triggered during startup
    if (routerNotifier.isPasswordRecovery) {
      context.go('/update-password');
      return;
    }

    if (session == null) {
      context.go('/login');
      return;
    }

    try {
      final isOnboarded = await routerNotifier.checkIsOnboarded(session.user.id);
      if (!mounted) return;

      if (isOnboarded) {
        context.go('/home');
      } else {
        context.go('/setup-profile');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: Stack(
        children: [
          // ── Ambient Background Glows ─────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB800).withValues(alpha: 0.10),
                ),
              ),
            ),
          ),

          // ── Center Content ──────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Character Mascot Card (Non-circular, squircle hero entrance)
                  Container(
                    width: 165,
                    height: 165,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.22),
                          blurRadius: 32,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                      // Hero spring-scale entrance
                      .animate()
                      .fade(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.65, 0.65),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                        duration: 850.ms,
                      )
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 750.ms,
                      )
                      // Shimmer highlight across the badge and cap
                      .shimmer(
                        delay: 750.ms,
                        duration: 1100.ms,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),

                  const SizedBox(height: 32),

                  // ── App Brand Title ──────────────────────────────────────
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE2E8F0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      'PRASHNIX',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.8,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .fade(delay: 350.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuart),

                  const SizedBox(height: 12),

                  // ── Khaki Motto Badge ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_police_rounded,
                          color: Color(0xFFFFB800),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'महाराष्ट्र पोलीस भरती परीक्षा',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFE2E8F0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(delay: 500.ms, duration: 550.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuart),

                  const Spacer(flex: 4),

                  // ── Minimalist Neon Charging Bar (No circle animation!) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        Container(
                          width: 220,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: CurvedAnimation(
                                  parent: _progressController,
                                  curve: Curves.easeInOutCubic,
                                ).value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF38EF7D),
                                        AppColors.primaryGreen,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGreen.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusText,
                            key: ValueKey(_statusText),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(delay: 600.ms, duration: 500.ms),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
