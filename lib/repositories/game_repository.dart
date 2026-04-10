import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';
import '../models/price_data.dart';
import '../controllers/auth_controller.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(Supabase.instance.client);
});

final allGamesProvider = FutureProvider<List<Game>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return [];
  return ref.read(gameRepositoryProvider).getGames(user.id);
});

class GameRepository {
  final SupabaseClient _client;

  GameRepository(this._client);

  Future<List<Game>> getGames(String userId) async {
    final response = await _client
        .from('games_with_valuations')
        .select()
        .eq('user_id', userId)
        .order('added_at', ascending: false);
    
    return (response as List<dynamic>)
        .map((e) => Game.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Game?> getGameById(String id) async {
    final response = await _client
        .from('games_with_valuations')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Game.fromJson(response);
  }

  Future<void> addGame(Game game) async {
    // Check for duplicates locally first
    if (game.externalId != null) {
      final existingIds = await _getExistingExternalIds(game.userId, game.platform);
      if (existingIds.contains(game.externalId)) return;
    }

    await _ensureCollection(game.collectionId, game.userId, game.platform);
    await _client.from('games').insert(game.toJson());
  }

  Future<void> addGamesBatch(List<Game> games) async {
    if (games.isEmpty) return;
    
    final userId = games.first.userId;
    final platform = games.first.platform;
    
    // Fetch currently tracked games to avoid duplicates
    final existingIds = await _getExistingExternalIds(userId, platform);
    
    // Filter out games that already exist
    final newGames = games.where((g) => !existingIds.contains(g.externalId)).toList();
    
    if (newGames.isEmpty) return;

    await _ensureCollection(games.first.collectionId, userId, platform);
    
    // Bulk insert only the new games
    await _client.from('games').insert(newGames.map((g) => g.toJson()).toList());
  }

  Future<Map<String, Game>> getExistingGamesByExternalIds(String userId, AppPlatform platform, List<String> externalIds) async {
    if (externalIds.isEmpty) return {};

    final response = await _client
        .from('games_with_valuations')
        .select()
        .eq('user_id', userId)
        .eq('platform', platform.value)
        .inFilter('external_id', externalIds);
    
    final Map<String, Game> gameMap = {};
    for (final json in (response as List<dynamic>)) {
      final game = Game.fromJson(json as Map<String, dynamic>);
      if (game.externalId != null) {
        gameMap[game.externalId!] = game;
      }
    }
    return gameMap;
  }

  Future<Set<String>> _getExistingExternalIds(String userId, AppPlatform platform) async {
    final response = await _client
        .from('games')
        .select('external_id')
        .eq('user_id', userId)
        .eq('platform', platform.value);
    
    return (response as List<dynamic>)
        .map((e) => e['external_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();
  }

  Future<void> _ensureCollection(String collectionId, String userId, AppPlatform platform) async {
    try {
      await _client.from('collections').upsert({
        'id': collectionId,
        'user_id': userId,
        'name': 'My Collection',
        'platform': platform.value,
      });
    } catch (e) {
      try {
        await _client.from('collections').upsert({
          'id': collectionId,
          'user_id': userId,
          'platform': platform.value,
        });
      } catch (innerE) {
         throw Exception('Could not ensure default collection exists. Details: $innerE');
      }
    }
  }

  /// Manually update valuation for a game.
  Future<void> updateValuation(String userId, String gameId, PriceData data) async {
    await _client.from('valuations').upsert({
      'game_id': gameId,
      'user_id': userId,
      'price_loose': data.loosePrice,
      'price_complete': data.cibPrice,
      'price_new': data.newPrice,
      'price_digital': data.digitalPrice,
      'source': data.source,
      'fetched_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteGame(String id, String userId) async {
    await _client.from('games').delete().eq('id', id).eq('user_id', userId);
  }

  Stream<List<Game>> getGamesStream(String userId) {
    return _client
        .from('games_with_valuations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('added_at', ascending: false)
        .map((response) => response
            .map((e) => Game.fromJson(e))
            .toList());
  }
}

final libraryStreamProvider = StreamProvider<List<Game>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(gameRepositoryProvider).getGamesStream(user.id);
});
