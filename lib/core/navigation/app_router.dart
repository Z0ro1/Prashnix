import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/terms_and_conditions_screen.dart';
import '../../features/auth/presentation/screens/setup_profile_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../widgets/main_navigation_screen.dart';
import '../../features/skill_tree/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/mistake_review_screen.dart';
import '../../features/quiz/presentation/screens/weekly_test_screen.dart';
import '../../features/gamification/presentation/screens/league_screen.dart';
import '../../features/gamification/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/saved_questions_screen.dart';
import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/leaderboard/presentation/screens/timed_exam_screen.dart';
import '../../features/leaderboard/presentation/screens/test_analytics_screen.dart';
import '../../features/gamification/presentation/screens/heart_details_screen.dart';
import '../config/supabase_config.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ─── Router Notifier ────────────────────────────────────────────────────────
// Listens to Riverpod state and notifies GoRouter to re-evaluate redirects.
// This caches the onboarding check to avoid hitting the DB on every route push.

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool? _isOnboardedCache;
  bool _isPasswordRecovery = false;

  bool get isPasswordRecovery => _isPasswordRecovery;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, next) {
      final authState = next.asData?.value;
      if (authState?.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      } else if (authState?.event == AuthChangeEvent.signedOut ||
                 authState?.event == AuthChangeEvent.userUpdated) {
        _isPasswordRecovery = false;
      }
      _isOnboardedCache = null; // Clear cache on auth change
      notifyListeners();
    });
  }

  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  Future<bool> checkIsOnboarded(String userId) async {
    if (_isOnboardedCache != null) return _isOnboardedCache!;

    try {
      final repo = AuthRepository();
      final profile = await repo.fetchUserProfile(userId);
      _isOnboardedCache = (profile != null && 
                           profile['username'] != null && 
                           profile['username'].toString().trim().isNotEmpty);
      return _isOnboardedCache!;
    } catch (e) {
      debugPrint('Error in checkIsOnboarded: $e');
      // Do not cache the error state. If there's a transient issue (e.g. expired token on startup),
      // we assume they are onboarded temporarily to avoid trapping them in the setup screen.
      // Once the token refreshes, authStateChanges will trigger a re-evaluation.
      return true;
    }
  }
  
  void forceRefresh() {
    _isOnboardedCache = null;
    notifyListeners();
  }
}

// ─── Router Provider ───────────────────────────────────────────────────────

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) async {
      final session = SupabaseConfig.client.auth.currentSession;
      final currentPath = state.uri.path;
      final isResetCallback = state.uri.host == 'reset-callback' || currentPath == '/reset-callback';

      // ── Step 0: Password Recovery Flow ───────────────────────────────
      if (isResetCallback || routerNotifier.isPasswordRecovery || currentPath == '/update-password') {
        if (isResetCallback) {
          return '/update-password';
        }
        if (routerNotifier.isPasswordRecovery || currentPath == '/update-password') {
          return currentPath == '/update-password' ? null : '/update-password';
        }
      }

      // Allow splash screen to display and control its own exit
      if (currentPath == '/' || currentPath == '/splash' || state.uri.host == 'splash') {
        if (currentPath == '/' || (state.uri.host == 'splash' && currentPath != '/splash')) {
          return '/splash';
        }
        return null;
      }

      // Public routes that don't require authentication
      const publicRoutes = ['/splash', '/login', '/forgot-password', '/terms', '/update-password'];
      final isOnPublicRoute = publicRoutes.contains(currentPath);

      // ── Step 1: Not logged in ────────────────────────────────────────
      if (session == null) {
        return isOnPublicRoute ? null : '/login';
      }

      // ── Step 2: Logged in — check onboarding ─────────────────────────
      final isOnSetupProfile = currentPath == '/setup-profile';
      
      // Use the cached checker
      final isOnboarded = await routerNotifier.checkIsOnboarded(session.user.id);

      // ── Step 3: Not onboarded — force to setup-profile ───────────────
      if (!isOnboarded) {
        return isOnSetupProfile ? null : '/setup-profile';
      }

      // ── Step 4: Fully authenticated & onboarded ──────────────────────
      // If they're trying to visit login or setup-profile, bounce to home
      if ((isOnPublicRoute && currentPath != '/splash') || isOnSetupProfile) {
        // Allow user to remain on /update-password if they came via recovery
        if (currentPath == '/update-password' && routerNotifier.isPasswordRecovery) {
          return null;
        }
        return '/home';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // ── Root Route ─────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),

      // ── Splash Screen ──────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth Routes ────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/reset-callback',
        redirect: (context, state) => '/update-password',
      ),

      // ── Profile Setup (Post-Auth Onboarding) ──────────────────────────
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),

      // ── Legacy onboarding route (redirects to setup-profile) ──────────
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) => '/setup-profile',
      ),

      // ── Main App Shell ─────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mistakes',
                builder: (context, state) => const MistakeReviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/weekly',
                builder: (context, state) => const WeeklyTestScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/league',
                builder: (context, state) => const LeagueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Top-Level Push Routes ──────────────────────────────────────────
      GoRoute(
        path: '/hearts',
        builder: (context, state) => const HeartDetailsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/saved_questions',
        builder: (context, state) => const SavedQuestionsScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/timed_exam',
        builder: (context, state) => const TimedExamScreen(),
      ),
      GoRoute(
        path: '/test_analytics',
        builder: (context, state) => const TestAnalyticsScreen(),
      ),
    ],
  );
});
