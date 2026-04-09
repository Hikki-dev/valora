import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class SteamAuthService {
  static const String steamOpenIdUrl = 'https://steamcommunity.com/openid/login';
  
  /// Generates the Steam OpenID login URL
  /// [returnUrl] should be the deep link or web URL to return to
  static Uri generateLoginUrl(String returnUrl) {
    final params = {
      'openid.ns': 'http://specs.openid.net/auth/2.0',
      'openid.mode': 'checkid_setup',
      'openid.return_to': returnUrl,
      'openid.realm': returnUrl,
      'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
      'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select',
    };

    final uri = Uri.parse(steamOpenIdUrl).replace(queryParameters: params);
    return uri;
  }

  /// Extracts the 64-bit Steam ID from the return URL
  static String? extractSteamId(String url) {
    try {
      final uri = Uri.parse(url);
      final claimedId = uri.queryParameters['openid.claimed_id'];
      if (claimedId == null) return null;
      
      // The identity URL looks like: https://steamcommunity.com/openid/id/76561198089456950
      final parts = claimedId.split('/');
      if (parts.isNotEmpty) {
        return parts.last;
      }
    } catch (e) {
      debugPrint('Error extracting Steam ID: $e');
    }
    return null;
  }

  /// Launches the Steam login flow
  static Future<void> launchLogin(String returnUrl) async {
    final url = generateLoginUrl(returnUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Steam login';
    }
  }
}
