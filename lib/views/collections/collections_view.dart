import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../repositories/game_repository.dart';
import '../../models/game.dart';
import 'add_game_modal.dart';
import '../../core/currency_provider.dart';
import '../../core/cache_manager.dart';
import '../../services/price_service.dart';
import 'game_detail_view.dart';

class SelectedSubCategory extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final selectedSubCategoryProvider =
    NotifierProvider<SelectedSubCategory, String>(
  SelectedSubCategory.new,
);
final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

final filteredGamesProvider = Provider.family
    .autoDispose<AsyncValue<List<Game>>, String?>((ref, platformFilter) {
  final gamesAsync = ref.watch(libraryStreamProvider);
  final subCategory = ref.watch(selectedSubCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();

  return gamesAsync.whenData((allGames) {
    var filtered = allGames.where((g) {
      if (platformFilter == null || platformFilter.isEmpty) return true;
      final p = g.platform.value;
      if (platformFilter == 'playstation') return p.startsWith('ps');
      if (platformFilter == 'ps_disc') {
        return p == 'ps4_physical' || p == 'ps5_physical';
      }
      if (platformFilter == 'psn') return p == 'ps4_digital' || p == 'ps5_digital';
      return p == platformFilter;
    }).toList();

    if (subCategory == 'PS5') {
      filtered =
          filtered.where((g) => g.platform.value.startsWith('ps5')).toList();
    }
    if (subCategory == 'PS4') {
      filtered =
          filtered.where((g) => g.platform.value.startsWith('ps4')).toList();
    }
    if (search.isNotEmpty) {
      filtered = filtered
          .where((g) => g.title.toLowerCase().contains(search))
          .toList();
    }

    return filtered;
  });
});

class CollectionsView extends ConsumerWidget {
  final String? platformFilter;

  const CollectionsView({super.key, this.platformFilter});

  String _getPlatformTitle() {
    if (platformFilter == 'playstation') return 'PlayStation';
    if (platformFilter == 'steam') return 'Steam Library';
    if (platformFilter == 'epic') return 'Epic Games';
    if (platformFilter == 'nintendo') return 'Nintendo';
    return 'My Library';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(filteredGamesProvider(platformFilter));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = textColor.withValues(alpha: 0.5);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(_getPlatformTitle(),
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context.pop(),
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop) const SizedBox(height: 16),
              if (isDesktop) ...[
                const SizedBox(height: 32),
                Text(
                  _getPlatformTitle(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Header Row (Mobile only or simplified desktop)
              if (!isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.chevron_left,
                            color: Colors.orangeAccent,
                            size: 24,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _getPlatformTitle(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.orangeAccent,
                        fontSize: 16,
                      ),
                    ),
                    gamesAsync.maybeWhen(
                      data: (games) => Text(
                        '${games.length}',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      orElse: () => const Text(
                        '...',
                        style: TextStyle(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              if (!isDesktop) const SizedBox(height: 24),

              // Overview Card (Compact Stats Bar)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Hug the content
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection value',
                          style: TextStyle(color: mutedTextColor, fontSize: 13),
                        ),
                        gamesAsync.maybeWhen(
                          data: (games) {
                            final total = games.fold<double>(
                              0.0,
                              (sum, g) => sum + (g.activeMarketValue ?? 0.0),
                            );
                            return Text(
                              ref.watch(currencyProvider).format(total),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700, // Standardized
                                fontFamily: 'Syne',
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                          orElse: () => Text(
                            '...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    // Subtle Vertical Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: textColor.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Games',
                          style: TextStyle(color: mutedTextColor, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        gamesAsync.maybeWhen(
                          data: (games) => Text(
                            '${games.length}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          orElse: () => Text(
                            '...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filter Chips
              if (platformFilter == 'playstation') ...[
                Row(
                  children: ['All', 'PS5', 'PS4'].map((category) {
                    final isSelected =
                        ref.watch(selectedSubCategoryProvider) == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(selectedSubCategoryProvider.notifier)
                                .set(category);
                          }
                        },
                        selectedColor: isDark ? Colors.white24 : Colors.black12,
                        backgroundColor: cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? textColor : mutedTextColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Search Bar
              TextField(
                onChanged: (val) =>
                    ref.read(searchQueryProvider.notifier).set(val),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search your collection...',
                  hintStyle: TextStyle(color: mutedTextColor),
                  prefixIcon: Icon(Icons.search, color: mutedTextColor),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.05),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Games Grid
              Expanded(
                child: gamesAsync.when(
                  data: (games) {
                    if (games.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return RefreshIndicator(
                      color: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      onRefresh: () async {
                        final stale =
                            games.where((g) => g.isPriceCacheStale).toList();
                        if (stale.isNotEmpty) {
                          await ref
                              .read(priceServiceProvider)
                              .fetchPricesBatch(stale);
                          ref.invalidate(libraryStreamProvider);
                        }
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final g = games[index];
                          return RepaintBoundary(
                            child: _buildGameCard(
                              context,
                              ref,
                              g,
                              cardColor,
                              textColor,
                              mutedTextColor,
                            )
                                .animate()
                                .fadeIn(
                                    duration: 400.ms, delay: (index * 50).ms)
                                .slideY(begin: 0.1, end: 0),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => _buildShimmerGrid(isDesktop),
                  error: (err, st) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(context),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    WidgetRef ref,
    Game game,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    Color accentColor = cardColor;
    final platformVal = game.platform.value;

    if (platformVal.startsWith('ps')) {
      accentColor = const Color(0xFF00439C);
    } else if (platformVal.startsWith('nintendo') ||
        platformVal.startsWith('switch')) {
      accentColor = const Color(0xFFE60012);
    } else if (platformVal == 'steam') {
      accentColor = const Color(0xFF171A21);
    } else if (platformVal == 'epic') {
      accentColor = const Color(0xFF303030);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) {
          // Preload data on touch start (mobile)
          ref.read(gameRepositoryProvider).getGameById(game.id);
          ref.read(gamePricesProvider(game.id));
        },
        onTap: () => context.push('/game/${game.id}'),
        child: MouseRegion(
          onEnter: (_) {
            // Preload data on hover (web)
            ref.read(gameRepositoryProvider).getGameById(game.id);
          },
          child: Hero(
            tag: 'game_cover_${game.id}',
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: textColor.withValues(alpha: 0.05)),
              ),
              clipBehavior: Clip.hardEdge,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover / Graphic area
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        color: accentColor.withValues(alpha: isDark ? 0.3 : 0.08),
                        child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: game.coverUrl!,
                                cacheManager: gameCoverCacheManager,
                                memCacheWidth: 300,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _FallbackCover(game: game),
                              )
                            : _FallbackCover(game: game),
                      ),
                    ),
                    // Details area
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              game.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ref
                                      .watch(currencyProvider)
                                      .format(game.activeMarketValue ?? 0.0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      game.condition.label,
                                      style: TextStyle(color: mutedTextColor, fontSize: 12),
                                    ),
                                    if (game.isPriceCacheStale)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.amberAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = textColor.withValues(alpha: 0.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 64,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),
          Text(
            _getEmptyMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: mutedTextColor,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptySubtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: mutedTextColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddGameModal(
                    initialPlatform: platformFilter != null
                        ? AppPlatform.fromString(platformFilter!)
                        : null),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add your first game'),
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon() {
    if (platformFilter == 'steam') return FontAwesomeIcons.steam;
    if (platformFilter?.startsWith('ps') == true) return FontAwesomeIcons.playstation;
    if (platformFilter == 'nintendo') return FontAwesomeIcons.gamepad;
    return Icons.videogame_asset_outlined;
  }

  String _getEmptyMessage() {
    if (platformFilter == 'steam') return 'Your Steam library\nis empty here';
    if (platformFilter?.startsWith('ps') == true) {
      return 'No PlayStation\ngames yet';
    }
    if (platformFilter == 'nintendo') return 'No Nintendo\ngames yet';
    return 'Nothing here yet';
  }

  String _getEmptySubtitle() {
    if (platformFilter == 'steam') {
      return 'Sync your Steam library or add games manually';
    }
    return 'Tap + to start tracking your collection';
  }

  Widget _buildShimmerGrid(bool isDesktop) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 32,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.surface),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddGameModal(
                initialPlatform: platformFilter != null
                    ? AppPlatform.fromString(platformFilter!)
                    : null),
          );
        },
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  final Game game;
  const _FallbackCover({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              game.platform.value.startsWith('ps')
                  ? FontAwesomeIcons.playstation
                  : game.platform.value == 'steam'
                      ? FontAwesomeIcons.steam
                      : Icons.videogame_asset,
              size: 32,
              color: Colors.white24,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                game.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
