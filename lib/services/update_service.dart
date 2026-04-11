import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool isUpdateAvailable;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.isUpdateAvailable,
  });
}

class UpdateService {
  static const String _owner = 'Hikki-dev';
  static const String _repo = 'valora';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null; // We only update the APK for Android

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String latestTag = data['tag_name'] as String? ?? '';
        final String htmlUrl = data['html_url'] as String? ?? '';

        if (latestTag.isEmpty) return null;

        // Clean version strings (v1.0.0 -> 1.0.0)
        final latestClean = latestTag.replaceAll('v', '');

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        final currentBuild = packageInfo.buildNumber;

        final isNewer = _isVersionNewer(
          latestClean,
          currentVersion,
          currentBuild: currentBuild,
        );

        return UpdateInfo(
          latestVersion: latestClean,
          downloadUrl: htmlUrl,
          isUpdateAvailable: isNewer,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Error checking for updates: $e');
    }
    return null;
  }

  bool _isVersionNewer(String latest, String current, {String? currentBuild}) {
    try {
      // Split by + to handle build numbers: "1.1.0+2" -> ["1.1.0", "2"]
      final latestFullParts = latest.split('+');
      final latestVersion = latestFullParts[0];
      final latestBuild = latestFullParts.length > 1 ? latestFullParts[1] : '0';

      final latestParts = latestVersion.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // 1. Compare major.minor.patch
      for (var i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }

      // If version parts match and latest has more segments, it's technically newer (e.g. 1.1.0.1 vs 1.1.0)
      if (latestParts.length > currentParts.length) return true;
      if (latestParts.length < currentParts.length) return false;

      // 2. Compare build numbers if semantic versions are identical
      final latestBuildNum = int.tryParse(latestBuild) ?? 0;
      final currentBuildNum = int.tryParse(currentBuild ?? '0') ?? 0;

      return latestBuildNum > currentBuildNum;
    } catch (e) {
      debugPrint('[UpdateService] Parsing error: $e');
      return latest != current;
    }
  }
}
