import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_notifier.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isComplete = false;
  bool? _hasRecoverySession;
  Timer? _verificationTimer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    authNotifier.addListener(_syncRecoverySession);
    _syncRecoverySession();
    _verificationTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _hasRecoverySession == true) return;
      setState(() => _hasRecoverySession = false);
    });
  }

  void _syncRecoverySession() {
    final hasSession = _authService.hasRecoverySession;
    if (mounted && hasSession) {
      _verificationTimer?.cancel();
      if (_hasRecoverySession != true) {
        setState(() => _hasRecoverySession = true);
      }
    } else if (mounted && _hasRecoverySession == null) {
      // Keep the verification state while Supabase establishes the session.
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    authNotifier.removeListener(_syncRecoverySession);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_isLoading || _hasRecoverySession != true) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.updatePassword(_passwordController.text);
      if (mounted) setState(() => _isComplete = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _backToLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (_authService.hasSession) {
        await _authService.signOut();
      }
      if (mounted) context.go('/login');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _passwordVisibilityButton(bool isObscured, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textMuted,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _backToLogin,
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isComplete ? 'Password Updated' : 'Reset Password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isComplete
                      ? 'Your password has been changed. You can now sign in with it.'
                      : _hasRecoverySession == null
                      ? 'Verifying this reset link...'
                      : _hasRecoverySession == true
                      ? 'Choose a new password for your account.'
                      : 'This reset link is missing or no longer valid.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
                if (!_isComplete && _hasRecoverySession == null)
                  const Center(child: CircularProgressIndicator())
                else if (!_isComplete && _hasRecoverySession == false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        label: 'Request a New Reset Link',
                        onPressed: () => context.go('/forgot-password'),
                      ),
                      const SizedBox(height: 12),
                      OutlineButton(
                        label: 'Back to Login',
                        onPressed: _backToLogin,
                      ),
                    ],
                  )
                else if (!_isComplete)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hint: 'At least 6 characters',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: _passwordVisibilityButton(
                            _obscurePassword,
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: _passwordVisibilityButton(
                            _obscureConfirmPassword,
                            () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _updatePassword(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm password is required';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: 'Update Password',
                          isLoading: _isLoading,
                          onPressed: _updatePassword,
                        ),
                      ],
                    ),
                  )
                else
                  PrimaryButton(
                    label: 'Back to Login',
                    isLoading: _isLoading,
                    onPressed: _backToLogin,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
