import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

enum AuthMode { signIn, signUp }

class AuthStateData {
  final AuthMode mode;
  final bool isLoading;
  final String? error;

  AuthStateData({
    this.mode = AuthMode.signIn,
    this.isLoading = false,
    this.error,
  });

  AuthStateData copyWith({
    AuthMode? mode,
    bool? isLoading,
    String? error,
  }) {
    return AuthStateData(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null to clear
    );
  }
}

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
      // Extract clean error message
      String message = e.toString();
      if (message.contains('Exception:')) {
        message = message.replaceAll('Exception:', '').trim();
      } else if (message.contains('AuthException:')) {
        message = message.replaceAll('AuthException:', '').trim();
      }
      state = state.copyWith(isLoading: false, error: message);
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
      String message = e.toString();
      if (message.contains('Exception:')) {
        message = message.replaceAll('Exception:', '').trim();
      } else if (message.contains('AuthException:')) {
        message = message.replaceAll('AuthException:', '').trim();
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }



  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}

// Stream provider for listening to Supabase Auth State globally
@riverpod
Stream<dynamic> authStateChanges(Ref ref) {
  return SupabaseConfig.client.auth.onAuthStateChange;
}
