import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/game_repository.dart';

class HomeState {
  final bool isLoading;
  final double totalValuation;
  final int totalGames;
  final bool hidePricing;
  final Map<String, PlatformStat> platformStats;

  HomeState({
    required this.isLoading,
    required this.totalValuation,
    required this.totalGames,
    required this.hidePricing,
    required this.platformStats,
  });

  factory HomeState.initial() => HomeState(
        isLoading: false,
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
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      totalValuation: totalValuation ?? this.totalValuation,
      totalGames: totalGames ?? this.totalGames,
      hidePricing: hidePricing ?? this.hidePricing,
      platformStats: platformStats ?? this.platformStats,
    );
  }
}

class PlatformStat {
  final int count;
  final double value;
  const PlatformStat(this.count, this.value);
}

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    Future.microtask(() => _loadDashboard());
    return HomeState.initial();
  }

  Future<void> _loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(gameRepositoryProvider);
      final games = await repo.getGames();
      
      double total = 0.0;
      Map<String, PlatformStat> stats = {};
      
      // Initialize with default groups
      Map<String, double> values = {'playstation': 0, 'steam': 0, 'nintendo': 0, 'epic': 0};
      Map<String, int> counts = {'playstation': 0, 'steam': 0, 'nintendo': 0, 'epic': 0};

      for (final g in games) {
        final val = g.activeMarketValue ?? 0.0;
        total += val;
        
        String group = 'steam'; // fallback
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
      
      for (final key in values.keys) {
        stats[key] = PlatformStat(counts[key]!, values[key]!);
      }
      
      state = state.copyWith(
        isLoading: false, 
        totalValuation: total, 
        totalGames: games.length,
        platformStats: stats,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        totalValuation: 0.0,
        totalGames: 0,
        platformStats: <String, PlatformStat>{},
      );
    }
  }

  void togglePricingVisibility() {
    state = state.copyWith(hidePricing: !state.hidePricing);
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(() {
  return HomeController();
});
