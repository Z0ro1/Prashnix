import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsignin;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository({
    SupabaseClient? supabaseClient,
  })  : _supabase = supabaseClient ?? SupabaseConfig.client;



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
      throw AuthException('Sign up failed: $e');
    }
  }

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
      throw AuthException('Sign in failed: $e');
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      const webClientId = '131351956530-jp7v80eqt5sot28e5pq3tigud6obqp10.apps.googleusercontent.com';
      
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

      if (idToken == null || accessToken == null) {
        throw const AuthException('Missing Google Auth Token');
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      throw AuthException('Google sign in failed: $e');
    }
  }

  Future<void> completeOnboarding({
    required String username,
    required String avatarId,
    required String district,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Must be signed in to complete onboarding.');
    }

    await _supabase.from('profiles').update({
      'username': username,
      'avatar_id': avatarId,
      'district': district,
      'is_onboarded': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
