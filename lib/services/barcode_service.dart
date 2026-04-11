import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BarcodeService {
  Future<Map<String, dynamic>?> fetchGameByUPC(String upc) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'lookup-barcode',
        body: {'upc': upc},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['found'] == true) {
          return {
            'title': _cleanTitle(data['title'] ?? 'Unknown Product'),
            'thumb': data['thumb'] ?? '',
            'upc': upc,
          };
        }
      }
    } catch (e) {
      debugPrint('[BarcodeService] Edge function error for UPC $upc: $e');
    }
    return null;
  }

  String _cleanTitle(String title) {
    // Remove common annoying suffixes from product databases
    return title
        .replaceAll(RegExp(r'\(.*?\)', caseSensitive: false),
            '') // Remove (PS4), (Import), etc.
        .replaceAll(RegExp(r'\[.*?\]', caseSensitive: false),
            '') // Remove [PlayStation 5]
        .replaceAll(RegExp(r'- PlayStation \d', caseSensitive: false), '')
        .replaceAll(RegExp(r'PS\d', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+', caseSensitive: false), ' ')
        .trim();
  }
}
