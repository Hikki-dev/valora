import 'game.dart';

class PriceData {
  final double? loosePrice;
  final double? cibPrice;
  final double? newPrice;
  final double? digitalPrice; // Added for digital games
  final String source;

  PriceData({
    this.loosePrice,
    this.cibPrice,
    this.newPrice,
    this.digitalPrice,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'loose': loosePrice,
        'cib': cibPrice,
        'new': newPrice,
        'digital': digitalPrice,
        'source': source,
      };

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
        loosePrice: (json['price_loose'] as num? ?? json['loose'] as num?)?.toDouble(),
        cibPrice: (json['price_complete'] as num? ?? json['cib'] as num?)
            ?.toDouble(),
        newPrice: (json['price_new'] as num? ?? json['new'] as num?)?.toDouble(),
        digitalPrice: (json['price_digital'] as num? ?? json['digital'] as num?)
            ?.toDouble(),
        source: json['source'] as String? ?? 'Unknown',
      );

  double? priceForCondition(GameCondition condition) {
    switch (condition) {
      case GameCondition.loose:
        return loosePrice;
      case GameCondition.cib:
      case GameCondition.boxed:
        return cibPrice;
      case GameCondition.new_:
        return newPrice;
    }
  }

  // Helper for backward compatibility or direct access in UI
  double? get currentPrice => digitalPrice ?? cibPrice ?? loosePrice;
}
