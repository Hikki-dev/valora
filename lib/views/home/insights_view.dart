import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../repositories/game_repository.dart';
import '../../models/game.dart';
import '../../core/currency_provider.dart';

class InsightsView extends ConsumerWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(allGamesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('COLLECTION INSIGHTS', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF14141A), const Color(0xFF0A0A0F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF0F0F5)],
          ),
        ),
        child: gamesAsync.when(
          data: (games) => _buildContent(context, ref, games, textColor),
          loading: () => _buildSkeleton(context, isDark),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Game> games, Color textColor) {
    if (games.isEmpty) {
      return Center(child: Text('No games in collection', style: TextStyle(color: textColor.withValues(alpha: 0.5))));
    }

    final sortedGames = List<Game>.from(games);
    sortedGames.sort((a, b) => (b.activeMarketValue ?? 0).compareTo(a.activeMarketValue ?? 0));

    final top10 = sortedGames.take(10).toList();
    final bottom10 = sortedGames.reversed.where((g) => (g.activeMarketValue ?? 0) > 0).take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('CROWN JEWELS', 'Most valuable assets', Icons.diamond_outlined, textColor),
          const SizedBox(height: 16),
          ...top10.asMap().entries.map((e) => _buildGameTile(context, ref, e.value, e.key + 1, textColor, true)),
          
          const SizedBox(height: 48),
          
          _buildSectionHeader('HIDDEN GEMS', 'Least valuable items', Icons.auto_awesome_mosaic_outlined, textColor),
          const SizedBox(height: 16),
          ...bottom10.asMap().entries.map((e) => _buildGameTile(context, ref, e.value, e.key + 1, textColor, false)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: Colors.cyanAccent)),
          ],
        ),
        Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildGameTile(BuildContext context, WidgetRef ref, Game game, int rank, Color textColor, bool isTop) {
    final currency = ref.watch(currencyProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text('#$rank', style: TextStyle(color: isTop ? Colors.cyanAccent : textColor.withValues(alpha: 0.3), fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: game.coverUrl ?? '',
              width: 45,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: textColor.withValues(alpha: 0.1)),
              errorWidget: (context, url, error) => Icon(Icons.image_not_supported, size: 20, color: textColor.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(game.platform.label, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currency.format(game.activeMarketValue ?? 0),
            style: TextStyle(
              color: isTop ? Colors.cyanAccent : textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    final highlightColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(width: 250, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            ...List.generate(5, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 84,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
