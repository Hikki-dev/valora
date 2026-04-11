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
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null; // We only update the APK for Android

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestTag = data['tag_name'] ?? '';
        final String htmlUrl = data['html_url'] ?? '';

        if (latestTag.isEmpty) return null;

        // Clean version strings (v1.0.0 -> 1.0.0)
        final latestClean = latestTag.replaceAll('v', '');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        final isNewer = _isVersionNewer(latestClean, currentVersion);

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

  bool _isVersionNewer(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (var i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (e) {
      return latest != current;
    }
  }
}
