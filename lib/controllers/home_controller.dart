import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class HomeState {
  final bool isLoading;
  final double totalValuation;
  final int totalGames;
  final bool hidePricing;
  final Map<String, PlatformStat> platformStats;
  final List<ValueSnapshot> valueHistory;
  final String? errorMessage;

  HomeState({
    required this.isLoading,
    required this.totalValuation,
    required this.totalGames,
    required this.hidePricing,
    required this.platformStats,
    this.valueHistory = const [],
    this.errorMessage,
  });

  double get weeklyDelta {
    if (valueHistory.length < 2) return 0.0;
    final latest = valueHistory.last.totalValue;
    // Calculate difference from 7 snapshots ago (or first if less than 7)
    final weekAgo = valueHistory.length >= 7
        ? valueHistory[valueHistory.length - 7].totalValue
        : valueHistory.first.totalValue;
    return latest - weekAgo;
  }

  factory HomeState.initial() => HomeState(
        isLoading: true,
        totalValuation: 0.0,
        totalGames: 0,
        hidePricing: false,
        platformStats: <String, PlatformStat>{},
        valueHistory: [],
      );

  HomeState copyWith({
    bool? isLoading,
    double? totalValuation,
    int? totalGames,
    bool? hidePricing,
    Map<String, PlatformStat>? platformStats,
    List<ValueSnapshot>? valueHistory,
    String? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      totalValuation: totalValuation ?? this.totalValuation,
      totalGames: totalGames ?? this.totalGames,
      hidePricing: hidePricing ?? this.hidePricing,
      platformStats: platformStats ?? this.platformStats,
      valueHistory: valueHistory ?? this.valueHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PlatformStat {
  final int count;
  final double value;
  const PlatformStat(this.count, this.value);
}

class ValueSnapshot {
  final DateTime date;
  final double totalValue;
  ValueSnapshot(this.date, this.totalValue);
}

final gameStatsProvider = Provider<HomeState>((ref) {
  final gamesAsync = ref.watch(libraryStreamProvider);
  return gamesAsync.when(
    data: (games) {
      double total = 0.0;
      Map<String, double> values = {'ps_disc': 0, 'psn': 0, 'steam': 0, 'nintendo': 0, 'epic': 0};
      Map<String, int> counts = {'ps_disc': 0, 'psn': 0, 'steam': 0, 'nintendo': 0, 'epic': 0};

      for (final g in games) {
        final val = g.activeMarketValue ?? 0.0;
        total += val;
        
        // Map granular internal platform values to dashboard summary categories
        String group = g.platform.value;
        if (group == 'ps4_physical' || group == 'ps5_physical') group = 'ps_disc';
        if (group == 'ps4_digital' || group == 'ps5_digital') group = 'psn';
        
        if (values.containsKey(group)) {
          values[group] = (values[group] ?? 0.0) + val;
          counts[group] = (counts[group] ?? 0) + 1;
        }
      }

      final stats = values.map((key, value) => MapEntry(key, PlatformStat(counts[key]!, value)));

      return HomeState(
        isLoading: false,
        totalValuation: total,
        totalGames: games.length,
        hidePricing: false,
        platformStats: stats,
      );
    },
    loading: () => HomeState.initial(),
    error: (err, st) => HomeState(
      isLoading: false,
      totalValuation: 0.0,
      totalGames: 0,
      hidePricing: false,
      platformStats: {},
      errorMessage: err.toString(),
    ),
  );
});

  @override
  HomeState build() {
    final stats = ref.watch(gameStatsProvider);
    unawaited(_fetchHistory());
    return stats.copyWith(
        hidePricing: stateOrNull?.hidePricing ?? false,
        valueHistory: stateOrNull?.valueHistory ?? []);
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await Supabase.instance.client
          .from('value_snapshots')
          .select()
          .order('snapped_at', ascending: true)
          .limit(30);
      
      final history = (response as List).map((e) {
        final item = e as Map<String, dynamic>;
        return ValueSnapshot(
          DateTime.parse(item['snapped_at'] as String),
          (item['total_value'] as num).toDouble(),
        );
      }).toList();

      state = state.copyWith(valueHistory: history);
    } catch (_) {
      // Fail silently for history
    }
  }

  void togglePricingVisibility() {
    state = state.copyWith(hidePricing: !state.hidePricing);
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(() {
  return HomeController();
});
