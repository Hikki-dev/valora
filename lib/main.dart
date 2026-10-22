import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'utils/platform_utils.dart';
import 'widgets/comic_loader.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedThemeMode();

  // SECURE: Values injected at build time, not bundled as files
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Validate at startup
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Missing',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The Supabase URL and Key were not found.\n\nPlease run with the following flag:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SelectableText(
                    'flutter run --dart-define-from-file=.env.build',
                    style: TextStyle(
                        color: Colors.orangeAccent, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }

  // Show the loader on the very first frame; the app swaps in once Supabase is ready.
  runApp(const BootGate());
}

/// Starts Supabase behind the comic loader instead of blocking runApp, so users see
/// motion immediately (web: the HTML splash hands over to this seamlessly).
class BootGate extends StatefulWidget {
  const BootGate({super.key});

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First frame is on screen: let the web splash fade out.
      PlatformUtils.signalFirstFrame();
    });
    _init();
  }

  Future<void> _init() async {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Startup Error (Supabase): $e');
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const ProviderScope(child: ValoraApp());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode,
      home: const Scaffold(
        body: ComicLoader(
          label: 'NOW LOADING…',
          steps: [
            LoaderStep('Starting up', active: true),
            LoaderStep('Signing you in'),
            LoaderStep('Loading your shelf'),
          ],
        ),
      ),
    );
  }
}
