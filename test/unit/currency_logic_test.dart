import 'package:flutter_test/flutter_test.dart';
import 'package:valora/core/currency_provider.dart';

void main() {
  group('CurrencyState Logic Tests', () {
    test('USD Formatting (Baseline)', () {
      final state = CurrencyState(currency: AppCurrency.usd, lkrRate: 300.0);
      expect(state.format(12.50), '\$12.50');
      expect(state.format(100.0), '\$100.00');
    });

    test('LKR Conversion and Formatting', () {
      final state = CurrencyState(currency: AppCurrency.lkr, lkrRate: 300.0);
      // 10 USD * 300 = 3000 LKR
      expect(state.format(10.0), 'Rs. 3000');
      // 1.5 USD * 300 = 450 LKR
      expect(state.format(1.5), 'Rs. 450');
    });

    test('LKR Precision/Rounding Check', () {
      final state = CurrencyState(currency: AppCurrency.lkr, lkrRate: 325.75);
      // 100 USD * 325.75 = 32575 LKR
      expect(state.format(100.0), 'Rs. 32575');
    });

    test('copyWith Functionality', () {
      final state = CurrencyState(currency: AppCurrency.usd, lkrRate: 300.0);
      final newState = state.copyWith(currency: AppCurrency.lkr);
      
      expect(newState.currency, AppCurrency.lkr);
      expect(newState.lkrRate, 300.0);
      
      final rateUpdate = newState.copyWith(lkrRate: 310.0);
      expect(rateUpdate.lkrRate, 310.0);
      expect(rateUpdate.currency, AppCurrency.lkr);
    });
  });
}
