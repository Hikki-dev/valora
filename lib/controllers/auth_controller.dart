import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

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
      // For mobile: use native google_sign_in
      // For web/alternative: use Supabase's built-in OAuth (redirect)
      
      if (Platform.isIOS || Platform.isAndroid) {
        // Native login flow
        final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
        final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
        
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? iosClientId : null,
          serverClientId: webClientId,
        );
        
        final googleUser = await googleSignIn.signIn();
        final googleAuth = await googleUser?.authentication;
        final accessToken = googleAuth?.accessToken;
        final idToken = googleAuth?.idToken;

        if (idToken == null) {
          throw 'No ID Token found.';
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } else {
        // Web flow
        await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
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
