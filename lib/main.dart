import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SECURE: Values injected at build time, not bundled as files
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Validate at startup
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('❌ Startup Error: Missing build-time env vars.');
    debugPrint('Run with: flutter run --dart-define-from-file=.env.build');
  }

  try {
    // Initialize Supabase with matching timeout to avoid hanging splash
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint("Startup Error (Supabase): $e");
    // We continue so the app can at least show the login/offline state
  }

  runApp(const ProviderScope(child: ValoraApp()));
}
