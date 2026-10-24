import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/ux_error_helper.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final success = await ref.read(authProvider.notifier).authenticate(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (!success && mounted) {
        final error = ref.read(authProvider).error;
        if (error != null) {
          _showError(error);
        }
      }
      // On success, GoRouter's refreshListenable will fire and
      // the redirect logic will navigate automatically.
    }
  }

  void _showError(Object error) {
    UxErrorHelper.show(context, error);
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController(text: _identifierController.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24).withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: AppColors.primaryMint.withValues(alpha: 0.3), width: 2)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryMint.withValues(alpha: 0.1)),
                        child: const Icon(Icons.lock_reset, color: AppColors.primaryMint, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text('Reset Password', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Enter your email and we will send you a secure reset link.', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: Colors.white54)),
                      const SizedBox(height: 24),
                      _buildGlassTextField(
                        controller: emailCtrl,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      Consumer(
                        builder: (context, ref, child) {
                          final isLoading = ref.watch(authProvider).isLoading;
                          return GestureDetector(
                            onTap: isLoading ? null : () async {
                              if (!emailCtrl.text.contains('@')) {
                                _showError('Please enter a valid email.');
                                return;
                              }
                              FocusScope.of(context).unfocus();
                              final success = await ref.read(authProvider.notifier).resetPassword(emailCtrl.text.trim());
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Password reset link sent! Check your inbox.'),
                                  backgroundColor: AppColors.primaryMint,
                                ));
                              } else {
                                final error = ref.read(authProvider).error;
                                if (error != null) _showError(error);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMint,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.3), blurRadius: 12)],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.deepTealNavy, strokeWidth: 2))
                                    : Text('SEND RESET LINK', style: AppTextStyles.h3.copyWith(color: AppColors.deepTealNavy, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: Icon(icon, color: Colors.white54),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              errorStyle: const TextStyle(color: AppColors.error),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isSignIn = authState.mode == AuthMode.signIn;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Animated Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMint.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.flash_on, color: AppColors.primaryMint, size: 50),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                 
                const SizedBox(height: 32),
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isSignIn ? 'Welcome back!' : 'Create your Profile',
                    key: ValueKey<bool>(isSignIn),
                    style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 8),
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isSignIn 
                        ? 'Enter your details to continue learning' 
                        : 'Join Spardha Sprint and start your journey',
                    key: ValueKey<bool>(isSignIn),
                    style: AppTextStyles.body.copyWith(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 48),

                // Identifier Field
                _buildGlassTextField(
                  controller: _identifierController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email address';
                    return null;
                  },
                ).animate().fade(delay: 300.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 16),

                // Password Field
                _buildGlassTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isVisible: _isPasswordVisible,
                  onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  textInputAction: isSignIn ? TextInputAction.done : TextInputAction.next,
                  onSubmitted: isSignIn ? (_) => _submit() : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (!isSignIn && value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ).animate().fade(delay: 400.ms).slideX(begin: -0.1, end: 0),
                
                // Confirm Password (Only on Sign Up)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !isSignIn
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: _buildGlassTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isVisible: _isConfirmPasswordVisible,
                            onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (!isSignIn && (value == null || value.isEmpty)) return 'Please confirm your password';
                              if (!isSignIn && value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ).animate().fade(delay: 500.ms),
                
                const SizedBox(height: 8),

                // Forgot Password (Only on Sign In)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: isSignIn
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordSheet,
                            child: Text(
                              'Forgot Password?',
                              style: AppTextStyles.label.copyWith(color: AppColors.primaryMint),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Primary Neon Submit Button
                GestureDetector(
                  onTap: authState.isLoading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMint,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryMint.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Center(
                      child: authState.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.deepTealNavy, strokeWidth: 2))
                          : Text(
                              isSignIn ? 'SIGN IN' : 'CREATE ACCOUNT',
                              style: AppTextStyles.h2.copyWith(color: AppColors.deepTealNavy, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: AppTextStyles.label.copyWith(color: Colors.white54)),
                    ),
                    const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                  ],
                ).animate().fade(delay: 700.ms),
                
                const SizedBox(height: 32),

                // Google Sign In Glass Button
                GestureDetector(
                  onTap: authState.isLoading ? null : () async {
                    FocusScope.of(context).unfocus();
                    final success = await ref.read(authProvider.notifier).signInWithGoogle();
                    if (!success && mounted) {
                      final error = ref.read(authProvider).error;
                      if (error != null) _showError(error);
                    }
                    // On success, GoRouter handles navigation automatically
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.g_mobiledata, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Continue with Google', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 800.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Toggle Mode
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).toggleMode();
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isSignIn ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                      key: ValueKey<bool>(isSignIn),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryMint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fade(delay: 900.ms),
                
                // Terms and Conditions (Only on Sign Up)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: !isSignIn
                      ? GestureDetector(
                          onTap: () => context.push('/terms'),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'By signing up, you agree to our Terms & Conditions',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
