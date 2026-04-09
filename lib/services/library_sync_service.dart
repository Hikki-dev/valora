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
        throw Exception('Sync service error: ${response.data['error'] ?? 'Unknown error'}');
      }

      final List<dynamic> gamesData = response.data['games'] ?? [];
      
      return gamesData.map((g) {
        return Game(
          id: 'steam_${g['externalId']}',
          collectionId: userId,
          userId: userId,
          title: g['title'] ?? 'Unknown Steam Game',
          coverUrl: g['coverUrl'],
          platform: AppPlatform.steam,
          format: 'Digital',
          externalId: g['externalId'],
        );
      }).toList();
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw Exception('Library syncing hasn\'t been deployed to your server yet. Please follow the instructions in the walkthrough!');
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
