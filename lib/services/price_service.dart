import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game.dart';
import '../models/price_data.dart';
import 'ebay_service.dart';

final priceServiceProvider = Provider<PriceService>((ref) {
  return PriceService(Supabase.instance.client);
});

class PriceService {
  final SupabaseClient _client;
  final EbayService _ebayService = EbayService();
  EbayService get ebayService => _ebayService;

  static const _priceChartingBase = 'https://www.pricecharting.com/api/product';
  static const _cheapSharkBase = 'https://www.cheapshark.com/api/1.0/games';

  PriceService(this._client);

  String get _priceChartingToken =>
      dotenv.env['PRICE_CHARTING_TOKEN'] ?? '';

  Future<PriceData?> fetchPrices(Game game, {bool force = false}) async {
    if (!force && !game.isPriceCacheStale && game.priceCache != null) {
      return game.priceCache;
    }

    PriceData? data;
    try {
      if (game.platform.isPhysical) {
        data = await _fetchPhysicalPrice(game);
      } else {
        data = await _fetchFromCheapShark(game.title);
      }
    } catch (e) {
      debugPrint('[PriceService] Fetch error for "${game.title}": $e');
    }

    if (data == null) return game.priceCache;

    try {
      await _client.from('games').update({
        'price_cache': data.toJson(),
        'price_fetched_at': DateTime.now().toIso8601String(),
      }).eq('id', game.id);
    } catch (e) {
      debugPrint('[PriceService] Cache write error: $e');
    }

    return data;
  }

  Future<void> refreshGameMetadata(Game game) async {
     // 1. Force refresh prices
     await fetchPrices(game, force: true);
     
     // 2. Try to find a better cover if currently missing or manual
     try {
       final uri = Uri.parse('$_cheapSharkBase?title=${Uri.encodeComponent(game.title)}&limit=1');
       final response = await http.get(uri);
       if (response.statusCode == 200) {
         final list = jsonDecode(response.body) as List<dynamic>;
         if (list.isNotEmpty) {
           final gameData = list.first as Map<String, dynamic>;
           final String? steamAppId = gameData['steamAppID'];
           final String? thumb = gameData['thumb'];
           
           String? newCover;
           if (steamAppId != null && steamAppId.isNotEmpty) {
             newCover = 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg';
           } else if (thumb != null && thumb.isNotEmpty) {
             newCover = thumb;
           }

           if (newCover != null && newCover != game.coverUrl) {
             await _client.from('games').update({
               'cover_url': newCover,
             }).eq('id', game.id);
           }
         }
       }
     } catch (e) {
       debugPrint('[PriceService] Metadata refresh error: $e');
     }
  }


  Future<PriceData?> _fetchPhysicalPrice(Game game) async {
    final token = _priceChartingToken;

    // 1. Try Official PriceCharting API (if not demo token)
    if (token.isNotEmpty && !token.startsWith('c0b53')) {
      final cleanTitle = _cleanTitle(game.title);
      final platform = game.platform.label;
      final data = await _executePriceChartingQuery('$cleanTitle $platform', token);
      if (data != null && (data.loosePrice != null || data.cibPrice != null)) {
        return data;
      }
    }

    // 2. Fallback to eBay Market Valuation
    debugPrint('[PriceService] Using eBay Market fallback for "${game.title}"');
    return await _ebayService.fetchMarketPrice(game);
  }

  Future<PriceData?> _executePriceChartingQuery(String query, String token) async {
    try {
      final uri = Uri.parse('$_priceChartingBase?q=${Uri.encodeComponent(query)}&t=$token');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] == 'error' || json['status'] == 'not found') return null;

      double? cents(String key) {
        final v = json[key];
        if (v == null || v == 0) return null;
        return (v as num).toDouble() / 100.0;
      }

      return PriceData(
        loosePrice: cents('loose-price'),
        cibPrice: cents('cib-price'),
        newPrice: cents('new-price'),
        source: 'PriceCharting',
      );
    } catch (_) {
      return null;
    }
  }

  Future<PriceData?> _fetchFromCheapShark(String title) async {
    try {
      final uri = Uri.parse('$_cheapSharkBase?title=${Uri.encodeComponent(title)}&limit=1');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;

      final gameData = list.first as Map<String, dynamic>;
      final cheapest = gameData['cheapest'];
      if (cheapest == null) return null;

      return PriceData(
        newPrice: double.tryParse(cheapest.toString()),
        source: 'CheapShark',
      );
    } catch (_) {
      return null;
    }
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll("'", "")
        .replaceAll(":", "")
        .replaceAll("-", " ")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
