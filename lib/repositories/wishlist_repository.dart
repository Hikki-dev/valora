import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_item.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(Supabase.instance.client);
});

class WishlistRepository {
  final SupabaseClient _client;

  WishlistRepository(this._client);

  Future<List<WishlistItem>> getWishlist() async {
    final response = await _client
        .from('wishlists')
        .select()
        .order('added_at', ascending: false);
    
    return (response as List<dynamic>)
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWishlistItem(WishlistItem item) async {
    await _client.from('wishlists').insert(item.toJson());
  }

  Future<void> deleteWishlistItem(String id) async {
    await _client.from('wishlists').delete().eq('id', id);
  }
}
