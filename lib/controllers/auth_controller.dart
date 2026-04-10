import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AuthController extends Notifier<AsyncValue<User?>> {
  @override
  AsyncValue<User?> build() {
    final session = Supabase.instance.client.auth.currentSession;
    return AsyncData(session?.user);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email, 
        password: password,
      );
      state = AsyncData(response.user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      state = AsyncData(response.user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      if (kIsWeb) {
        // Web flow: Redirect (Stable on Vercel)
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.toString() : 'com.valora.app://login-callback',
        );
      } else {
        // Mobile flow: ID Token (Seamless/Native)
        const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
        const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
        
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? iosClientId : null, // Handled automatically on Android
          serverClientId: webClientId,
        );
        
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          state = const AsyncData(null); // User cancelled
          return;
        }

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'No ID Token found.';
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await Supabase.instance.client.auth.signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<User?>>(() {
  return AuthController();
});
