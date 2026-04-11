import 'package:flutter_test/flutter_test.dart';
import 'package:valora/models/game.dart';

void main() {
  group('AppPlatform Logic Tests', () {
    test('Platform Identification (Physical vs Digital)', () {
      expect(AppPlatform.ps5Physical.isPhysical, isTrue);
      expect(AppPlatform.nintendo.isPhysical, isTrue);
      
      expect(AppPlatform.steam.isDigital, isTrue);
      expect(AppPlatform.ps5Digital.isDigital, isTrue);
    });

    test('Platform Brand Detection', () {
      expect(AppPlatform.ps4Physical.isPlayStation, isTrue);
      expect(AppPlatform.ps5Digital.isPlayStation, isTrue);
      expect(AppPlatform.steam.isPlayStation, isFalse);
    });

    test('Platform Parsing (Legacy Support)', () {
      expect(AppPlatform.fromString('playstation_physical'), AppPlatform.ps4Physical);
      expect(AppPlatform.fromString('psn_digital'), AppPlatform.ps4Digital);
      expect(AppPlatform.fromString('steam'), AppPlatform.steam);
      expect(AppPlatform.fromString('unknown_val'), AppPlatform.steam); // Fallback
    });
    
    test('Platform Display Labels', () {
      expect(AppPlatform.ps5Physical.label, 'PS5');
      expect(AppPlatform.steam.label, 'Steam');
      expect(AppPlatform.nintendo.label, 'Nintendo');
    });
  });
}
