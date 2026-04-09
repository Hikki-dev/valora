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

  /// Centralized session refresh logic to prevent concurrent race conditions.
  static Future<void>? _refreshFuture;

  Future<void> _ensureValidSession() async {
    final session = _client.auth.currentSession;
    if (session != null && !session.isExpired) return;

    if (_refreshFuture != null) {
      debugPrint('[PriceService] Waiting for existing session refresh...');
      return _refreshFuture;
    }

    debugPrint('[PriceService] Starting synchronized session refresh...');
    _refreshFuture = _client.auth.refreshSession().then((_) {
      _refreshFuture = null;
    }).catchError((e) {
      _refreshFuture = null;
      throw e;
    });

    return _refreshFuture;
  }

  /// Fetches the latest price for a game via the centralized Edge Function.
  /// This handles caching, rate limiting, and multi-source lookups (Steam, PriceCharting, CheapShark).
  Future<PriceData?> fetchPrices(Game game, {bool force = false, int retryCount = 0}) async {
    try {
      await _ensureValidSession();

      final response = await _client.functions.invoke(
        'fetch-price',
        body: {
          'gameId': game.id,
          'platform': game.platform.value,
          'externalId': game.externalId,
          'title': game.title,
          'forceRefresh': force,
        },
        headers: {
          'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken}',
          'X-Internal-Secret': 'vlr_9a2b5c7d8e1f4a3b92837465',
        },
      );

      if (response.status != 200) {
        debugPrint('[PriceService] Function error: ${response.data}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final priceData = PriceData.fromJson(data);
      
      // If we got a better cover URL, update the game record
      final newCoverUrl = data['cover_url'] as String?;
      if (newCoverUrl != null && newCoverUrl.isNotEmpty && newCoverUrl != game.coverUrl) {
        debugPrint('[PriceService] Found better cover art for "${game.title}". Synchronizing...');
        _client.from('games').update({'cover_url': newCoverUrl}).eq('id', game.id).then((_) {
          debugPrint('[PriceService] Cover updated for "${game.title}".');
        });
      }

      return priceData;
    } catch (e) {
      if (e is FunctionException && e.status == 401) {
        if (retryCount == 0) {
          debugPrint('[PriceService] AUTH ERROR (401). Retrying with fresh session...');
          // Invalidate future to force a hard refresh on retry
          _refreshFuture = null; 
          await _ensureValidSession();
          return fetchPrices(game, force: force, retryCount: 1);
        }
        debugPrint('[PriceService] AUTH ERROR: Invalid or expired JWT. Price fetching failed for "${game.title}".');
      } else {
        debugPrint('[PriceService] Invoke error for "${game.title}": $e');
      }
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
