import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsignin;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository({
    SupabaseClient? supabaseClient,
  })  : _supabase = supabaseClient ?? SupabaseConfig.client;

  // ─── Username Availability ───────────────────────────────────────────

  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
          
      return response == null; // True if null, meaning available
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // ─── Email Sign Up ───────────────────────────────────────────────────

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('Sign up failed: ${_extractMessage(e)}');
    }
  }

  // ─── Email Sign In ───────────────────────────────────────────────────

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('Sign in failed: ${_extractMessage(e)}');
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────────────

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      if (webClientId.isEmpty) {
        throw const AuthException(
          'Google Web Client ID is not configured. '
          'Add GOOGLE_WEB_CLIENT_ID to your .env file.',
        );
      }
      
      final googleSignIn = gsignin.GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the login
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('Missing Google ID Token');
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign in failed: ${_extractMessage(e)}');
    }
  }

  // ─── Onboarding / Profile Setup ──────────────────────────────────────

  Future<void> completeOnboarding({
    required String username,
    required String avatarId,
    required String district,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Must be signed in to complete onboarding.');
    }

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'username': username,
      'avatar_id': avatarId,
      'district': district,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Fetch Profile ───────────────────────────────────────────────────

  /// Returns the profile row for [userId], or null if no profile row exists.
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      throw Exception('Failed to fetch profile: ${_extractMessage(e)}');
    }
  }

  // ─── Password Reset ─────────────────────────────────────────────────

  Future<void> resetPasswordForEmail({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.crexst.streak://reset-callback',
      );
    } catch (e) {
      throw AuthException('Password reset failed: ${_extractMessage(e)}');
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AuthException('Failed to update password: ${_extractMessage(e)}');
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Strips Dart exception class prefixes to produce a user-friendly message.
  String _extractMessage(Object e) {
    String message = e.toString();
    // Strip common prefixes
    for (final prefix in ['AuthException:', 'Exception:', 'PostgrestException:']) {
      if (message.contains(prefix)) {
        message = message.split(prefix).last.trim();
        break;
      }
    }
    return message;
  }
}
