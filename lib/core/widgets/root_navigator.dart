import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/data/repositories/progress_repository.dart';
import 'main_navigation_screen.dart';
import '../config/supabase_config.dart';

class RootNavigator extends ConsumerWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateChangesProvider);

    return authStateAsync.when(
      data: (authState) {
        final session = authState is AuthState ? authState.session : SupabaseConfig.client.auth.currentSession;
        
        if (session == null) {
          // User is not logged in
          return const AuthScreen();
        }

        // User is logged in, check if they are onboarded
        return FutureBuilder<bool>(
          future: _checkIfUserIsOnboarded(session.user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isOnboarded = snapshot.data ?? false;

            if (isOnboarded) {
              return const MainNavigationScreen();
            } else {
              return const OnboardingScreen();
            }
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<bool> _checkIfUserIsOnboarded(String userId) async {
    try {
      final progressRepo = ProgressRepository();
      final localStatus = await progressRepo.getLocalState('is_onboarded');
      if (localStatus == '1') {
        return true;
      }

      final response = await SupabaseConfig.client
          .from('profiles')
          .select('is_onboarded')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['is_onboarded'] == true) {
        await progressRepo.saveLocalState('is_onboarded', '1');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
