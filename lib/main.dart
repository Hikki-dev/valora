import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? "",
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? "",
    );
  } catch (e) {
    debugPrint("Startup Error: $e");
    // We still call runApp so the app doesn't just 'disappear' with a white screen
  }

  runApp(const ProviderScope(child: ValoraApp()));
}
