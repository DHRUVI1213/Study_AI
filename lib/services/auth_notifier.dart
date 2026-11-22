import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Notifies GoRouter when auth state changes so redirects stay in sync.
class AuthNotifier extends ChangeNotifier {
  bool _listening = false;
  bool _initialized = false;
  bool _isPasswordRecovery = false;

  bool get isPasswordRecovery => _isPasswordRecovery;

  void startListening() {
    if (_listening || !SupabaseConfig.isConfigured) return;
    _listening = true;
    _initialized = true;
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.passwordRecovery:
          _isPasswordRecovery = true;
          break;
        case AuthChangeEvent.signedOut:
          _isPasswordRecovery = false;
          break;
        case AuthChangeEvent.signedIn:
          if (state.session == null) _isPasswordRecovery = false;
          break;
        default:
          break;
      }
      notifyListeners();
    });
  }

  bool get isLoggedIn {
    if (!_initialized || !SupabaseConfig.isConfigured) return false;
    return !_isPasswordRecovery &&
        Supabase.instance.client.auth.currentSession != null;
  }
}

final authNotifier = AuthNotifier();

String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Wrong email or password. Please try again.';
    }
    if (message.contains('recovery') ||
        message.contains('token has expired') ||
        message.contains('otp_expired') ||
        message.contains('invalid token') ||
        message.contains('invalid grant')) {
      return 'This password reset link is invalid or has expired. Please request a new link.';
    }
    if (message.contains('password') &&
        (message.contains('weak') ||
            message.contains('short') ||
            message.contains('least'))) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email first, or disable email confirmation in Supabase for testing.';
    }
    if (message.contains('user already registered')) {
      return 'This email is already registered. Try signing in instead.';
    }
    return error.message;
  }
  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('failed host') ||
      text.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
