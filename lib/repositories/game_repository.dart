import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';
import '../models/price_data.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(Supabase.instance.client);
});

final allGamesProvider = FutureProvider<List<Game>>((ref) async {
  return ref.read(gameRepositoryProvider).getGames();
});




class GameRepository {
  final SupabaseClient _client;

  GameRepository(this._client);

  Future<List<Game>> getGames() async {
    final response = await _client
        .from('games')
        .select()
        .order('added_at', ascending: false);
    
    return (response as List<dynamic>)
        .map((e) => Game.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Game?> getGameById(String id) async {
    final response = await _client
        .from('games')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Game.fromJson(response);
  }

  Future<void> addGame(Game game) async {
    try {
      await _client.from('collections').upsert({
        'id': game.collectionId,
        'user_id': game.userId,
        'name': 'My Collection',
        'platform': game.platform.value,
      });
    } catch (e) {
      try {
        await _client.from('collections').upsert({
          'id': game.collectionId,
          'user_id': game.userId,
          'platform': game.platform.value,
        });
      } catch (innerE) {
         throw Exception('Could not ensure default collection exists. Details: $innerE');
      }
    }

    await _client.from('games').insert(game.toJson());
  }

  /// Writes fetched price data back to the Supabase row.
  Future<void> updatePriceCache(String gameId, PriceData data) async {
    await _client.from('games').update({
      'price_cache': data.toJson(),
      'price_fetched_at': DateTime.now().toIso8601String(),
    }).eq('id', gameId);
  }

  Future<void> deleteGame(String id) async {
    await _client.from('games').delete().eq('id', id);
  }
}
