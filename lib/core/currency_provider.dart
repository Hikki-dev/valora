import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AppCurrency { usd, lkr }

class CurrencyState {
  final AppCurrency currency;
  final double lkrRate;

  CurrencyState({required this.currency, required this.lkrRate});

  CurrencyState copyWith({AppCurrency? currency, double? lkrRate}) {
    return CurrencyState(
      currency: currency ?? this.currency,
      lkrRate: lkrRate ?? this.lkrRate,
    );
  }

  String format(double usdValue) {
    if (currency == AppCurrency.usd) {
      return '\$${usdValue.toStringAsFixed(2)}';
    } else {
      return 'Rs. ${(usdValue * lkrRate).toStringAsFixed(0)}';
    }
  }
}

class CurrencyNotifier extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    Future.microtask(() => _init());
    return CurrencyState(currency: AppCurrency.usd, lkrRate: 300.0);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isLkr = prefs.getBool('use_lkr') ?? false;
    final cachedRate = prefs.getDouble('lkr_rate');
    
    if (cachedRate != null) {
      state = state.copyWith(currency: isLkr ? AppCurrency.lkr : AppCurrency.usd, lkrRate: cachedRate);
    } else if (isLkr) {
      state = state.copyWith(currency: AppCurrency.lkr);
    }
    
    _fetchLiveRate();
  }

  Future<void> _fetchLiveRate() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates']['LKR'] as num).toDouble();
        state = state.copyWith(lkrRate: rate);
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setDouble('lkr_rate', rate);
      }
    } catch (_) {
      // Keep cached or default rate
    }
  }

  void toggleCurrency() async {
    final newCurrency = state.currency == AppCurrency.usd ? AppCurrency.lkr : AppCurrency.usd;
    state = state.copyWith(currency: newCurrency);
    
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('use_lkr', newCurrency == AppCurrency.lkr);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, CurrencyState>(() {
  return CurrencyNotifier();
});
