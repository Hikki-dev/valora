import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/game_repository.dart';

class HomeState {
  final bool isLoading;
  final double totalValuation;
  final int totalGames;
  final bool hidePricing;
  final Map<String, PlatformStat> platformStats;
  final String? errorMessage;

  HomeState({
    required this.isLoading,
    required this.totalValuation,
    required this.totalGames,
    required this.hidePricing,
    required this.platformStats,
    this.errorMessage,
  });

  factory HomeState.initial() => HomeState(
        isLoading: true,
        totalValuation: 0.0,
        totalGames: 0,
        hidePricing: false,
        platformStats: <String, PlatformStat>{},
      );

  HomeState copyWith({
    bool? isLoading,
    double? totalValuation,
    int? totalGames,
    bool? hidePricing,
    Map<String, PlatformStat>? platformStats,
    String? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      totalValuation: totalValuation ?? this.totalValuation,
      totalGames: totalGames ?? this.totalGames,
      hidePricing: hidePricing ?? this.hidePricing,
      platformStats: platformStats ?? this.platformStats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PlatformStat {
  final int count;
  final double value;
  const PlatformStat(this.count, this.value);
}

final gameStatsProvider = Provider<HomeState>((ref) {
  final gamesAsync = ref.watch(allGamesProvider);
  return gamesAsync.when(
    data: (games) {
      double total = 0.0;
      Map<String, double> values = {'playstation': 0, 'steam': 0, 'nintendo': 0, 'epic': 0};
      Map<String, int> counts = {'playstation': 0, 'steam': 0, 'nintendo': 0, 'epic': 0};

      for (final g in games) {
        final val = g.activeMarketValue ?? 0.0;
        total += val;
        
        String group = 'steam';
        if (g.platform.value.startsWith('ps')) {
          group = 'playstation';
        } else if (g.platform.value == 'nintendo') {
          group = 'nintendo';
        } else if (g.platform.value == 'epic') {
          group = 'epic';
        }
        
        values[group] = (values[group] ?? 0.0) + val;
        counts[group] = (counts[group] ?? 0) + 1;
      }

      final stats = values.map((key, value) => MapEntry(key, PlatformStat(counts[key]!, value)));

      return HomeState(
        isLoading: false,
        totalValuation: total,
        totalGames: games.length,
        hidePricing: false, // Default, will be overridden by controller
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

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    final stats = ref.watch(gameStatsProvider);
    // Persist local UI state like hidePricing
    // We can use a separate provider for hidePricing too for better optimization
    return stats.copyWith(hidePricing: stateOrNull?.hidePricing ?? false);
  }

  void togglePricingVisibility() {
    state = state.copyWith(hidePricing: !state.hidePricing);
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(() {
  return HomeController();
});
