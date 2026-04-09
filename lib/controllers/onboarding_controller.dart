import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../views/onboarding/onboarding_content.dart';

enum OnboardingType { none, full, changelog }

class OnboardingState {
  final OnboardingType type;
  final int lastSeenCount;

  OnboardingState({required this.type, this.lastSeenCount = 0});

  static OnboardingState none() => OnboardingState(type: OnboardingType.none);
}

class OnboardingController extends Notifier<OnboardingState> {
  bool _hasChecked = false;

  @override
  OnboardingState build() => OnboardingState.none();

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
    final lastSeenChangelogCount = prefs.getInt('seen_changelog_count') ?? profile?.seenChangelogCount ?? 0;

    debugPrint('[Onboarding] 🛠️ Version Comparison:');
    debugPrint('[Onboarding] Current App Version: $currentVersion');
    debugPrint('[Onboarding] Supabase Last Seen: $supabaseLastSeen');
    debugPrint('[Onboarding] Local Device Last Seen: $localLastSeen');
    debugPrint('[Onboarding] Seen Changelog Items: $lastSeenChangelogCount');

    // Decision Logic: Hybrid Approach (Remote + Local)
    // If BOTH are null, it's a completely new user -> Full Intro
    // If local says we've seen it, trust local as a fallback for FULL INTRO
    final hasOnboardedRemotely = supabaseLastSeen != null;
    final hasOnboardedLocally = localLastSeen != null;

    if (!hasOnboardedRemotely && !hasOnboardedLocally) {
      debugPrint('[Onboarding] ✅ Decision: FULL INTRO (Syncing/New Account)');
      state = OnboardingState(type: OnboardingType.full);
    } else if (lastSeenChangelogCount < OnboardingContent.changelog.length) {
       debugPrint('[Onboarding] ✅ Decision: CHANGELOG (New items found)');
       state = OnboardingState(type: OnboardingType.changelog, lastSeenCount: lastSeenChangelogCount);
    } else {
      debugPrint('[Onboarding] 💤 Decision: NONE (Already seen remotely or locally)');
      state = OnboardingState.none();
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
    await prefs.setInt('seen_changelog_count', OnboardingContent.changelog.length);

    // Update Supabase
    try {
       await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'last_seen_version': currentVersion,
        'seen_changelog_count': OnboardingContent.changelog.length,
        'onboarded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle error or ignore if table doesn't exist yet
    }

    state = OnboardingState.none();
    _hasChecked = true;
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, OnboardingState>(() {
  return OnboardingController();
});
