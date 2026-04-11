import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';

abstract class LibraryProvider {
  String get name;
  Future<List<Game>> fetchLibrary(String userId);
}

class SteamLibraryProvider implements LibraryProvider {
  final String steamId;

  SteamLibraryProvider({required this.steamId});

  @override
  String get name => 'Steam';

  @override
  Future<List<Game>> fetchLibrary(String userId) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'sync-steam',
        body: {'steamId': steamId},
      );

      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>;
        throw Exception(
            'Sync service error: ${data['error'] ?? 'Unknown error'}');
      }

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> gamesData = data['games'] ?? [];

      return gamesData.map((gObj) {
        final g = gObj as Map<String, dynamic>;
        final String? externalId = g['externalId']?.toString();
        return Game(
          id: 'steam_$externalId',
          collectionId: userId,
          userId: userId,
          title: g['title']?.toString() ?? 'Unknown Steam Game',
          coverUrl: externalId != null
              ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$externalId/library_600x900.jpg'
              : g['coverUrl']?.toString(),
          platform: AppPlatform.steam,
          format: 'Digital',
          externalId: externalId,
        );
      }).toList();
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw Exception(
            'Library syncing hasn\'t been deployed to your server yet. Please follow the instructions in the walkthrough!');
      }
      throw Exception('Could not connect to sync service: ${e.reasonPhrase}');
    } catch (e) {
      throw Exception('Failed to fetch Steam library: $e');
    }
  }
}

class LibrarySyncService {
  final Ref ref;
  LibrarySyncService(this.ref);

  Future<List<Game>> syncSteam(String userId, String steamId) async {
    final provider = SteamLibraryProvider(steamId: steamId);
    return await provider.fetchLibrary(userId);
  }
}

final librarySyncServiceProvider = Provider((ref) => LibrarySyncService(ref));
