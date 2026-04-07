import 'game.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String title;
  final String? coverUrl;
  final AppPlatform platform;
  final String? externalId;
  final double? targetPrice;
  final double? currentPrice;
  
  WishlistItem({
    required this.id,
    required this.userId,
    required this.title,
    this.coverUrl,
    required this.platform,
    this.externalId,
    this.targetPrice,
    this.currentPrice,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      platform: AppPlatform.fromString(json['platform'] as String),
      externalId: json['external_id'] as String?,
      targetPrice: (json['target_price'] as num?)?.toDouble(),
      currentPrice: (json['current_price'] as num?)?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'cover_url': coverUrl,
      'platform': platform.value,
      'external_id': externalId,
      'target_price': targetPrice,
      'current_price': currentPrice,
    };
  }
}
