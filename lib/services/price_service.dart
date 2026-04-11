import 'dart:async';
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

    // Check if session exists and has at least 60 seconds remaining
    // (avoids a race where the token expires mid-request)
    if (session != null && !session.isExpired) {
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final secondsRemaining =
            expiresAt - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
        if (secondsRemaining > 60) {
          return; // More than 1 minute left, we're fine
        }
      } else {
        return; // No expiry info, assume valid
      }
    }

    if (_refreshFuture != null) {
      debugPrint('[PriceService] Waiting for existing session refresh...');
      return _refreshFuture;
    }

    debugPrint(
        '[PriceService] Session expiring soon or expired. Refreshing...');
    _refreshFuture = _client.auth.refreshSession().then((_) {
      _refreshFuture = null;
      debugPrint('[PriceService] Session refreshed successfully.');
    }).catchError((e) {
      _refreshFuture = null;
      debugPrint('[PriceService] Session refresh failed: $e');
      throw e;
    });

    return _refreshFuture;
  }

  /// Fetches the latest price for a game via the centralized Edge Function.
  /// This handles caching, rate limiting, and multi-source lookups (Steam, PriceCharting, CheapShark).
  Future<PriceData?> fetchPrices(Game game,
      {bool force = false, int retryCount = 0}) async {
    try {
      await _ensureValidSession();

      // Explicitly read the CURRENT session token after ensuring it's valid.
      // Do NOT rely on the SDK's internal reference — it can be stale.
      final accessToken = _client.auth.currentSession?.accessToken;
      if (accessToken == null) {
        debugPrint(
            '[PriceService] No access token available for "${game.title}".');
        return null;
      }

      final response = await _client.functions.invoke(
        'fetch-price',
        body: {
          'gameId': game.id,
          'platform': _mapPlatformForEdge(game.platform),
          'externalId': game.externalId,
          'title': game.title,
          'forceRefresh': force,
        },
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.status == 401 && retryCount == 0) {
        // Token was valid when we read it, but the function still rejected it.
        // Force a hard refresh and retry exactly once.
        debugPrint(
            '[PriceService] 401 on "${game.title}". Forcing hard session refresh...');
        _refreshFuture = null;
        await _client.auth.refreshSession();
        return fetchPrices(game, force: force, retryCount: 1);
      }

      if (response.status != 200) {
        debugPrint(
            '[PriceService] Function returned ${response.status} for "${game.title}": ${response.data}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final priceData = PriceData.fromJson(data);

      // If we got a better cover URL, update the game record silently
      final newCoverUrl = data['cover_url'] as String?;
      if (newCoverUrl != null &&
          newCoverUrl.isNotEmpty &&
          newCoverUrl != game.coverUrl) {
        unawaited(_client
            .from('games')
            .update({'cover_url': newCoverUrl}).eq('id', game.id));
      }

      return priceData;
    } catch (e) {
      debugPrint('[PriceService] Invoke error for "${game.title}": $e');
      return null;
    }
  }

  String _mapPlatformForEdge(AppPlatform platform) {
    switch (platform) {
      case AppPlatform.ps4Physical:
      case AppPlatform.ps5Physical:
        return 'ps_disc';
      case AppPlatform.ps4Digital:
      case AppPlatform.ps5Digital:
        return 'psn';
      case AppPlatform.steam:
        return 'steam';
      case AppPlatform.epic:
        return 'epic';
      case AppPlatform.nintendo:
        return 'nintendo';
    }
  }

  /// Refreshes both price and metadata (like high-res covers).
  Future<void> refreshGameMetadata(Game game) async {
    // metadata is now partially handled by the edge function logic or another update
    // For now, we strictly refresh the price which updates the valuations table.
    await fetchPrices(game, force: true);
  }

  /// Bulk refresh for a list of games (chunked to avoid rate limiting)
  Future<void> fetchPricesBatch(List<Game> games) async {
    const int chunkSize = 5;
    for (var i = 0; i < games.length; i += chunkSize) {
      final end = (i + chunkSize < games.length) ? i + chunkSize : games.length;
      final chunk = games.sublist(i, end);

      debugPrint(
          '[PriceService] Batching chunk ${i ~/ chunkSize + 1} (${chunk.length} items)...');
      await Future.wait(chunk.map((g) => fetchPrices(g)));

      if (end < games.length) {
        // Small delay between chunks to let the server breathe
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
}
