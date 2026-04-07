import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BarcodeService {
  static const _baseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';

  Future<Map<String, dynamic>?> fetchGameByUPC(String upc) async {
    try {
      final uri = Uri.parse('$_baseUrl?upc=$upc');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>;
        
        if (items.isNotEmpty) {
          final item = items.first as Map<String, dynamic>;
          return {
            'title': _cleanTitle(item['title'] ?? 'Unknown Product'),
            'thumb': (item['images'] as List<dynamic>?)?.first ?? '',
            'upc': upc,
          };
        }
      }
    } catch (e) {
      debugPrint('[BarcodeService] Error looking up UPC $upc: $e');
    }
    return null;
  }

  String _cleanTitle(String title) {
    // Remove common annoying suffixes from product databases
    return title
        .replaceAll(RegExp(r'\(.*?\)', caseSensitive: false), '') // Remove (PS4), (Import), etc.
        .replaceAll(RegExp(r'\[.*?\]', caseSensitive: false), '') // Remove [PlayStation 5]
        .replaceAll(RegExp(r'- PlayStation \d', caseSensitive: false), '')
        .replaceAll(RegExp(r'PS\d', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+', caseSensitive: false), ' ')
        .trim();
  }
}
