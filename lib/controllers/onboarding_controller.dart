import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

enum OnboardingState { none, full, changelog }

class OnboardingController extends Notifier<OnboardingState> {
  bool _hasChecked = false;

  @override
  OnboardingState build() => OnboardingState.none;

  Future<void> checkOnboarding() async {
    if (_hasChecked) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Check local device version
    final localLastSeen = prefs.getString('last_seen_version');
    
    // 2. Check Supabase profile version
    Profile? profile;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (response != null) {
        profile = Profile.fromJson(response);
      }
    } catch (e) {
      debugPrint('[Onboarding] Profile fetch failed or empty: $e');
    }

    final supabaseLastSeen = profile?.lastSeenVersion;

    debugPrint('[Onboarding] 🛠️ Version Comparison:');
    debugPrint('[Onboarding] Current App Version: $currentVersion');
    debugPrint('[Onboarding] Supabase Last Seen: $supabaseLastSeen');
    debugPrint('[Onboarding] Local Device Last Seen: $localLastSeen');

    // Decision Logic:
    // If supabaseLastSeen is null, it's a completely new user -> Full Intro
    // If localLastSeen != currentVersion, it's a new device or update -> Intro/Changelog
    
    if (supabaseLastSeen == null) {
      debugPrint('[Onboarding] ✅ Decision: FULL INTRO (New Account)');
      state = OnboardingState.full;
    } else if (supabaseLastSeen != currentVersion) {
       debugPrint('[Onboarding] ✅ Decision: CHANGELOG (Version Update)');
       state = OnboardingState.changelog;
    } else {
      debugPrint('[Onboarding] 💤 Decision: NONE (Already saw this version)');
      state = OnboardingState.none;
    }
    _hasChecked = true;
  }

  Future<void> completeOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final prefs = await SharedPreferences.getInstance();

    // Update Local
    await prefs.setString('last_seen_version', currentVersion);

    // Update Supabase
    try {
       await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'last_seen_version': currentVersion,
        'onboarded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle error or ignore if table doesn't exist yet
    }

    state = OnboardingState.none;
    _hasChecked = true;
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, OnboardingState>(() {
  return OnboardingController();
});
