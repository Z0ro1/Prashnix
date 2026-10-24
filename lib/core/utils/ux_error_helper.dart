import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class UxError {
  final String headline;
  final String description;
  final String primaryAction;
  final String secondaryAction;
  final String illustrationVibe;

  const UxError({
    required this.headline,
    required this.description,
    required this.primaryAction,
    required this.secondaryAction,
    required this.illustrationVibe,
  });
}

class UxErrorHelper {
  /// Translates raw exceptions into UX-friendly error messages
  static UxError translate(Object e) {
    if (e is SocketException) {
      return const UxError(
        headline: "You're offline",
        description: "We couldn't connect. Please check your internet to load your progress.",
        primaryAction: "Try Again",
        secondaryAction: "Play Offline",
        illustrationVibe: "disconnected_plug",
      );
    }
    
    if (e is DatabaseException) {
      return const UxError(
        headline: "Taking a breather",
        description: "We hit a tiny snag reading your data. Restart the app to fix this.",
        primaryAction: "Restart App",
        secondaryAction: "Contact Support",
        illustrationVibe: "robot_wrench",
      );
    }

    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return const UxError(
          headline: "Hold on a second",
          description: "That email and password didn't match. Please try again.",
          primaryAction: "Try Again",
          secondaryAction: "Reset Password",
          illustrationVibe: "padlock_shake",
        );
      }
      if (msg.contains('already registered') || msg.contains('user already exists')) {
        return const UxError(
          headline: "You've been here before!",
          description: "An account already exists with that email. Want to log in instead?",
          primaryAction: "Log In",
          secondaryAction: "Use Different Email",
          illustrationVibe: "id_badges",
        );
      }
      if (msg.contains('password should be at least')) {
        return const UxError(
          headline: "Let's make it stronger",
          description: "Your password is too easy to guess. Add numbers and symbols for safety.",
          primaryAction: "Edit Password",
          secondaryAction: "Dismiss",
          illustrationVibe: "bicep_padlock",
        );
      }
      return UxError(
        headline: "Authentication Error",
        description: e.message,
        primaryAction: "Try Again",
        secondaryAction: "Dismiss",
        illustrationVibe: "padlock",
      );
    }

    if (e is PostgrestException) {
      if (e.code == '23505') { // Unique violation
        return const UxError(
          headline: "Let's double-check that",
          description: "That username is taken. Try adding some numbers or picking a new one!",
          primaryAction: "Edit Username",
          secondaryAction: "Dismiss",
          illustrationVibe: "name_tag_taken",
        );
      }
      return const UxError(
        headline: "Couldn't load your info",
        description: "We had a problem fetching your data right now. Give it a refresh.",
        primaryAction: "Refresh",
        secondaryAction: "Go Home",
        illustrationVibe: "empty_book",
      );
    }

    final str = e.toString().toLowerCase();
    if (str.contains('timeout')) {
      return const UxError(
        headline: "Lost in transmission",
        description: "This is taking too long to load. Make sure you have a strong signal.",
        primaryAction: "Retry",
        secondaryAction: "Go Home",
        illustrationVibe: "snail_radar",
      );
    }

    // Default Fallback Error
    return const UxError(
      headline: "Oops, something broke",
      description: "We ran into an unexpected hiccup. Please try again in a moment.",
      primaryAction: "Try Again",
      secondaryAction: "Dismiss",
      illustrationVibe: "confused_robot",
    );
  }

  /// Displays the UX Error as a beautiful bottom sheet
  static void show(BuildContext context, Object error) {
    final uxError = translate(error);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 90.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon (Simulating the vibe)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  uxError.headline,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  uxError.description,
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Primary Action
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        uxError.primaryAction,
                        style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary Action
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        uxError.secondaryAction,
                        style: AppTextStyles.h3.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
