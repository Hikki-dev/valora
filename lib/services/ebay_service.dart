import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/game.dart';
import '../models/price_data.dart';

class EbayService {
  static const String _ebayBase = 'https://www.ebay.com/sch/i.html';

  Future<PriceData?> fetchMarketPrice(Game game) async {
    try {
      final queryTitle = _cleanTitle(game.title);
      final region = game.region ?? '';
      
      // Construct eBay Sold search URL
      // LH_Sold=1: Show only sold items
      // LH_Complete=1: Show only completed auctions/listings
      final query = Uri.encodeComponent('$queryTitle ${game.platform.label} $region');
      final url = '$_ebayBase?_nkw=$query&LH_Sold=1&LH_Complete=1';

      debugPrint('[EbayService] Searching: $url');

      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[EbayService] Http Error: ${response.statusCode}');
        return null;
      }

      final body = response.body;
      final prices = _extractPrices(body);

      if (prices.isEmpty) {
        debugPrint('[EbayService] No sold listings found for "${game.title}"');
        return null;
      }

      // Calculate average (excluding outliers if we have enough data)
      final avgPrice = _calculateAveragedPrice(prices);
      debugPrint('[EbayService] Found ${prices.length} sales. Avg Market: \$$avgPrice');

      return PriceData(
        loosePrice: avgPrice * 0.8, // Estimated loose price
        cibPrice: avgPrice,         // eBay "Sold" usually reflects CIB/Boxed
        newPrice: avgPrice * 1.5,   // Estimated for new
        source: 'eBay (Market Avg)',
      );
    } catch (e) {
      debugPrint('[EbayService] Error: $e');
      return null;
    }
  }

  List<double> _extractPrices(String html) {
    final List<double> results = [];
    
    // Pattern for eBay prices: looks for class="s-item__price" or class="s-card__price"
    // Captures amounts like $45.00 or GBP 32.50
    // We look for the "POSITIVE" price which is the sold price
    final regex = RegExp(r'(?:s-item__price|s-card__price)[^>]*>\s*<span class="positive">\s*(?:[A-Z]+\s*)?\$?([\d,]+\.\d{2})');
    final matches = regex.allMatches(html);

    for (final match in matches) {
      final priceStr = match.group(1)?.replaceAll(',', '');
      if (priceStr != null) {
        final val = double.tryParse(priceStr);
        if (val != null && val > 0) {
          results.add(val);
        }
      }
      // Only take top 10 results for a safe average
      if (results.length >= 10) break;
    }

    // Fallback regex if "positive" class is not used (sometimes happens)
    if (results.isEmpty) {
      final fallbackRegex = RegExp(r'(?:s-item__price|s-card__price)[^>]*>\s*(?:<[^>]+>)?\s*(?:[A-Z]+\s*)?\$?([\d,]+\.\d{2})');
      final fallbackMatches = fallbackRegex.allMatches(html);
      for (final match in fallbackMatches) {
        final priceStr = match.group(1)?.replaceAll(',', '');
        if (priceStr != null) {
          final val = double.tryParse(priceStr);
          if (val != null && val > 0) {
            results.add(val);
          }
        }
        if (results.length >= 10) break;
      }
    }

    return results;
  }

  double _calculateAveragedPrice(List<double> prices) {
    if (prices.isEmpty) return 0.0;
    
    // Sort and remove top/bottom 10% to eliminate outliers if we have enough data
    prices.sort();
    
    if (prices.length >= 5) {
      final subList = prices.sublist(1, prices.length - 1);
      return subList.reduce((a, b) => a + b) / subList.length;
    }
    
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove parentheses content
        .replaceAll("'", "")
        .replaceAll(":", "")
        .replaceAll("-", " ")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
