import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'auth_notifier.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => _client.auth.currentSession != null;
  bool get hasSession => _client.auth.currentSession != null;
  bool get hasRecoverySession =>
      authNotifier.isPasswordRecovery && _client.auth.currentSession != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user == null) {
      throw const AuthException('Could not create account. Please try again.');
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session == null) {
      throw const AuthException(
        'Login failed. If you just signed up, verify your email first.',
      );
    }

    return response;
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb
          ? '${Uri.base.origin}/#/reset-password'
          : 'io.supabase.aistudyassistant://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateDisplayName(String fullName) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
    final userId = currentUser?.id;
    if (userId != null) {
      try {
        await _client
            .from('profiles')
            .update({'full_name': fullName})
            .eq('id', userId);
      } catch (_) {
        // Safe fallback in case profile table updates fail
      }
    }
  }

  Future<void> updateEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  String? get userDisplayName {
    final meta = currentUser?.userMetadata;
    return meta?['full_name'] as String? ??
        currentUser?.email?.split('@').first;
  }

  String? get userEmail => currentUser?.email;

  String? get userAvatarUrl =>
      currentUser?.userMetadata?['avatar_url'] as String?;
}

Future<void> initializeSupabase() async {
  if (!SupabaseConfig.isConfigured) return;
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  authNotifier.startListening();
}
