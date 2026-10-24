import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// ─── Auth Mode ──────────────────────────────────────────────────────────────

enum AuthMode { signIn, signUp }

// ─── Auth UI State ──────────────────────────────────────────────────────────

class AuthStateData {
  final AuthMode mode;
  final bool isLoading;
  final Object? error;

  AuthStateData({
    this.mode = AuthMode.signIn,
    this.isLoading = false,
    this.error,
  });

  AuthStateData copyWith({
    AuthMode? mode,
    bool? isLoading,
    Object? error,
  }) {
    return AuthStateData(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null to clear
    );
  }
}

// ─── Auth Notifier ──────────────────────────────────────────────────────────

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthRepository _authRepository;

  @override
  AuthStateData build() {
    _authRepository = AuthRepository();
    return AuthStateData();
  }

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn,
      error: null, // Clear error on switch
    );
  }

  Future<bool> authenticate({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.mode == AuthMode.signUp) {
        // Enforce email for sign up
        if (!identifier.contains('@')) {
          throw Exception('Please enter a valid email address to sign up.');
        }
        await _authRepository.signUpWithEmail(email: identifier, password: password);
        // Supabase auto-logs in after signup if email confirmation is disabled.
      } else {
        await _authRepository.signInWithEmail(email: identifier, password: password);
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authRepository.signInWithGoogle();
      if (response == null) {
        // User canceled login
        state = state.copyWith(isLoading: false);
        return false; 
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.resetPasswordForEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // _cleanError removed - we use UxErrorHelper directly now
}

// ─── Auth State Stream ──────────────────────────────────────────────────────
// This stream is watched by GoRouter so route redirects re-evaluate on
// every sign-in / sign-out event.

@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  return SupabaseConfig.client.auth.onAuthStateChange;
}

// ─── Profile / Onboarding Status ────────────────────────────────────────────
// Fetches the profile from Supabase whenever the auth state changes.
// Returns null if the user is unauthenticated or has no profile row yet.

@riverpod
Future<Map<String, dynamic>?> userProfile(Ref ref) async {
  // Re-evaluate whenever the auth session changes
  ref.watch(authStateChangesProvider);

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;

  try {
    final repo = AuthRepository();
    return await repo.fetchUserProfile(user.id);
  } catch (e) {
    debugPrint('Failed to fetch user profile: $e');
    return null;
  }
}
