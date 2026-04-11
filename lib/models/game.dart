// import 'price_data.dart';

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
      case ps5Physical:
        return 'PS5';
      case ps4Physical:
        return 'PS4';
      case ps5Digital:
        return 'PS5 Digital';
      case ps4Digital:
        return 'PS4 Digital';
      case steam:
        return 'Steam';
      case epic:
        return 'Epic Games';
      case nintendo:
        return 'Nintendo';
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
  final double? purchasePrice;
  final double? estimatedValue;

  // View fields (valuations)
  final double? priceLoose;
  final double? priceComplete;
  final double? priceNew;
  final double? priceDigital;
  final String? currency;
  final String? source;
  final DateTime? fetchedAt;
  final double? currentValue;

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
    this.purchasePrice,
    this.estimatedValue,
    this.priceLoose,
    this.priceComplete,
    this.priceNew,
    this.priceDigital,
    this.currency,
    this.source,
    this.fetchedAt,
    this.currentValue,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
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
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      estimatedValue: (json['estimated_value'] as num?)?.toDouble(),
      priceLoose: (json['price_loose'] as num?)?.toDouble(),
      priceComplete: (json['price_complete'] as num?)?.toDouble(),
      priceNew: (json['price_new'] as num?)?.toDouble(),
      priceDigital: (json['price_digital'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      source: json['source'] as String?,
      fetchedAt: json['fetched_at'] != null
          ? DateTime.tryParse(json['fetched_at'] as String)
          : null,
      currentValue: (json['current_value'] as num?)?.toDouble(),
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
      'purchase_price': purchasePrice,
      'estimated_value': estimatedValue,
    };
  }

  Game copyWith({
    String? id,
    String? collectionId,
    String? userId,
    String? title,
    String? coverUrl,
    AppPlatform? platform,
    String? externalId,
    String? genre,
    String? publisher,
    int? releaseYear,
    String? format,
    String? region,
    GameCondition? condition,
    double? purchasePrice,
    double? estimatedValue,
    double? priceLoose,
    double? priceComplete,
    double? priceNew,
    double? priceDigital,
    String? currency,
    String? source,
    DateTime? fetchedAt,
    double? currentValue,
  }) {
    return Game(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      platform: platform ?? this.platform,
      externalId: externalId ?? this.externalId,
      genre: genre ?? this.genre,
      publisher: publisher ?? this.publisher,
      releaseYear: releaseYear ?? this.releaseYear,
      format: format ?? this.format,
      region: region ?? this.region,
      condition: condition ?? this.condition,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      priceLoose: priceLoose ?? this.priceLoose,
      priceComplete: priceComplete ?? this.priceComplete,
      priceNew: priceNew ?? this.priceNew,
      priceDigital: priceDigital ?? this.priceDigital,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  double? get activeMarketValue =>
      currentValue ?? estimatedValue ?? purchasePrice;

  double get profitOrLoss {
    final paid = purchasePrice ?? 0.0;
    final market = activeMarketValue ?? 0.0;
    return market - paid;
  }

  bool get isPriceCacheStale {
    if (fetchedAt == null) return true;
    final ttlHours = platform.isDigital ? 6 : 24;
    return DateTime.now().difference(fetchedAt!).inHours >= ttlHours;
  }
}
