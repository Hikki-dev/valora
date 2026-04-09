import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game.dart';
import '../models/price_data.dart';

final priceServiceProvider = Provider<PriceService>((ref) {
  return PriceService(Supabase.instance.client);
});

class PriceService {
  final SupabaseClient _client;

  PriceService(this._client);

  /// Fetches the latest price for a game via the centralized Edge Function.
  /// This handles caching, rate limiting, and multi-source lookups (Steam, PriceCharting, CheapShark).
  Future<PriceData?> fetchPrices(Game game, {bool force = false}) async {
    try {
      final response = await _client.functions.invoke(
        'fetch-price',
        body: {
          'gameId': game.id,
          'platform': game.platform.value,
          'externalId': game.externalId,
          'title': game.title,
          'forceRefresh': force,
        },
      );

      if (response.status != 200) {
        debugPrint('[PriceService] Function error: ${response.data}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      return PriceData.fromJson(data);
    } catch (e) {
      debugPrint('[PriceService] Invoke error for "${game.title}": $e');
      return null;
    }
  }

  /// Refreshes both price and metadata (like high-res covers).
  Future<void> refreshGameMetadata(Game game) async {
    // metadata is now partially handled by the edge function logic or another update
    // For now, we strictly refresh the price which updates the valuations table.
    await fetchPrices(game, force: true);
  }

  /// Bulk refresh for a list of games (optimally handled concurrently)
  Future<void> fetchPricesBatch(List<Game> games) async {
    final futures = games.map((g) => fetchPrices(g));
    await Future.wait(futures);
  }
}
