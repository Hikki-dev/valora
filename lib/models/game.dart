import 'price_data.dart';

enum GameCondition {
  loose('Loose'),
  cib('CIB'),
  boxed('Boxed'),
  new_('New');

  final String label;
  const GameCondition(this.label);

  static GameCondition fromString(String? val) {
    if (val == null) return GameCondition.cib;
    return GameCondition.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => GameCondition.cib,
    );
  }
}

enum AppPlatform {
  ps4Physical('ps4_physical'),
  ps5Physical('ps5_physical'),
  ps4Digital('ps4_digital'),
  ps5Digital('ps5_digital'),
  steam('steam'),
  epic('epic'),
  nintendo('nintendo');

  final String value;
  const AppPlatform(this.value);

  static AppPlatform fromString(String val) {
    if (val == 'playstation_physical') return AppPlatform.ps4Physical;
    if (val == 'psn_digital') return AppPlatform.ps4Digital;

    return AppPlatform.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AppPlatform.steam,
    );
  }

  bool get isPhysical => value.contains('physical') || this == nintendo;
  bool get isPlayStation => value.startsWith('ps');
  bool get isDigital => !isPhysical;

  String get label {
    switch (this) {
      case ps5Physical: return 'PS5';
      case ps4Physical: return 'PS4';
      case ps5Digital: return 'PS5 Digital';
      case ps4Digital: return 'PS4 Digital';
      case steam: return 'Steam';
      case epic: return 'Epic Games';
      case nintendo: return 'Nintendo';
    }
  }
}

class Game {
  final String id;
  final String collectionId;
  final String userId;
  final String title;
  final String? coverUrl;
  final AppPlatform platform;
  final String? externalId;
  final String? genre;
  final String? publisher;
  final int? releaseYear;
  
  final String format; 
  final String? region;
  final GameCondition condition; 
  final double? estimatedValue;
  final double? purchasePrice;

  final PriceData? priceCache;
  final DateTime? priceFetchedAt;

  Game({
    required this.id,
    required this.collectionId,
    required this.userId,
    required this.title,
    this.coverUrl,
    required this.platform,
    this.externalId,
    this.genre,
    this.publisher,
    this.releaseYear,
    this.format = 'Digital',
    this.region,
    this.condition = GameCondition.cib,
    this.estimatedValue,
    this.purchasePrice,
    this.priceCache,
    this.priceFetchedAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    PriceData? priceCache;
    final rawCache = json['price_cache'];
    if (rawCache is Map<String, dynamic>) {
      priceCache = PriceData.fromJson(rawCache);
    }

    DateTime? priceFetchedAt;
    final rawTs = json['price_fetched_at'];
    if (rawTs != null) {
      priceFetchedAt = DateTime.tryParse(rawTs as String);
    }

    return Game(
      id: json['id'] as String,
      collectionId: json['collection_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      platform: AppPlatform.fromString(json['platform'] as String),
      externalId: json['external_id'] as String?,
      genre: json['genre'] as String?,
      publisher: json['publisher'] as String?,
      releaseYear: json['release_year'] as int?,
      format: json['format'] as String? ?? 'Digital',
      region: json['region'] as String?,
      condition: GameCondition.fromString(json['condition'] as String?),
      estimatedValue: (json['estimated_value'] as num?)?.toDouble(),
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      priceCache: priceCache,
      priceFetchedAt: priceFetchedAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'collection_id': collectionId,
      'user_id': userId,
      'title': title,
      'cover_url': coverUrl,
      'platform': platform.value,
      'external_id': externalId,
      'genre': genre,
      'publisher': publisher,
      'release_year': releaseYear,
      'format': format,
      'region': region,
      'condition': condition.label,
      'estimated_value': estimatedValue,
      'purchase_price': purchasePrice,
    };
  }

  double? get activeMarketValue {
    if (priceCache != null) {
      return priceCache!.priceForCondition(condition);
    }
    return estimatedValue ?? purchasePrice;
  }

  double get profitOrLoss {
    final paid = purchasePrice ?? 0.0;
    final marketAtCondition = activeMarketValue ?? 0.0;
    return marketAtCondition - paid;
  }

  bool get isPriceCacheStale {
    if (priceFetchedAt == null) return true;
    return DateTime.now().difference(priceFetchedAt!).inHours >= 24;
  }
}
