// lib/core/auth/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  /// Signs the user in with Google and creates a Supabase session.
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Google idToken is null');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  /// Signs the user out from both Google and Supabase.
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _client.auth.signOut(),
    ]);
  }
}
