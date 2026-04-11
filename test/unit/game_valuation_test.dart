import 'package:flutter_test/flutter_test.dart';
import 'package:valora/models/game.dart';

void main() {
  group('Game Valuation & Cache Logic Tests', () {
    final baseGame = Game(
      id: 'test-1',
      collectionId: 'col-1',
      userId: 'user-1',
      title: 'Tarkov',
      platform: AppPlatform.steam,
      purchasePrice: 40.0,
      format: 'Digital',
    );

    test('Profit/Loss Calculation', () {
      final gameWithGain = baseGame.copyWith(currentValue: 60.0);
      expect(gameWithGain.profitOrLoss, 20.0);

      final gameWithLoss = baseGame.copyWith(currentValue: 30.0);
      expect(gameWithLoss.profitOrLoss, -10.0);
    });

    test('Active Market Value Priority', () {
      // Priority: Current Appraisal > Estimated > Purchase
      final game1 = baseGame.copyWith(estimatedValue: 50.0);
      expect(game1.activeMarketValue, 50.0);

      final game2 = game1.copyWith(currentValue: 70.0);
      expect(game2.activeMarketValue, 70.0);

      expect(baseGame.activeMarketValue, 40.0);
    });

    test('Price Cache Stale Logic - Digital (6h TTL)', () {
      final now = DateTime.now();
      
      final freshGame = baseGame.copyWith(
        fetchedAt: now.subtract(const Duration(hours: 5)),
      );
      expect(freshGame.isPriceCacheStale, isFalse);

      final staleGame = baseGame.copyWith(
        fetchedAt: now.subtract(const Duration(hours: 7)),
      );
      expect(staleGame.isPriceCacheStale, isTrue);
    });

    test('Price Cache Stale Logic - Physical (24h TTL)', () {
      final now = DateTime.now();
      final physicalGame = baseGame.copyWith(
        platform: AppPlatform.ps5Physical,
        fetchedAt: now.subtract(const Duration(hours: 23)),
      );
      expect(physicalGame.isPriceCacheStale, isFalse);

      final stalePhysical = physicalGame.copyWith(
        fetchedAt: now.subtract(const Duration(hours: 25)),
      );
      expect(stalePhysical.isPriceCacheStale, isTrue);
    });
  });
}
