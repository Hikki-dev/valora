import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../repositories/game_repository.dart';
import '../../models/game.dart';
import 'add_game_modal.dart';
import '../../core/currency_provider.dart';

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

final filteredGamesProvider = FutureProvider.family
    .autoDispose<List<Game>, String?>((ref, platformFilter) async {
      final allGames = await ref.watch(libraryStreamProvider.future);


      final subCategory = ref.watch(selectedSubCategoryProvider);
      final search = ref.watch(searchQueryProvider).toLowerCase();

      var filtered = allGames.where((g) {
        if (platformFilter != null && platformFilter.isNotEmpty) {
          final p = g.platform.value;
          
          if (platformFilter == 'playstation') {
            if (!p.startsWith('ps')) return false;
          } else if (platformFilter == 'ps_disc') {
            if (p != 'ps4_physical' && p != 'ps5_physical') return false;
          } else if (platformFilter == 'psn') {
            if (p != 'ps4_digital' && p != 'ps5_digital') return false;
          } else if (p != platformFilter) {
            return false;
          }
        }
        return true;
      }).toList();

      if (subCategory != 'All') {
        if (subCategory == 'PS5') {
          filtered = filtered
              .where((g) => g.platform.value.startsWith('ps5'))
              .toList();
        }
        if (subCategory == 'PS4') {
          filtered = filtered
              .where((g) => g.platform.value.startsWith('ps4'))
              .toList();
        }
      }

      if (search.isNotEmpty) {
        filtered = filtered
            .where((g) => g.title.toLowerCase().contains(search))
            .toList();
      }

      return filtered;
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
      appBar: isDesktop ? null : AppBar(
        title: Text(_getPlatformTitle(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          color: Colors.orangeAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 4),
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
                    style: TextStyle(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Syne',
                                color: Colors.white,
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
                      return Center(
                        child: Text(
                          "No games found.",
                          style: TextStyle(color: mutedTextColor, fontSize: 16),
                        ),
                      );
                    }
                    return GridView.builder(
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
                          ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
                        );
                      },
                    );
                  },
                  loading: () => _buildShimmerGrid(isDesktop),
                  error: (err, st) => Center(
                    child: Text(
                      'Error: $err',
                      style: TextStyle(color: Colors.redAccent),
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
    Color cardBgColor = cardColor;
    if (game.title.toLowerCase().contains('spider')) {
      cardBgColor = Colors.red.withValues(alpha: 0.05);
    } else if (game.title.toLowerCase().contains('horizon') ||
        game.title.toLowerCase().contains('zelda')) {
      cardBgColor = Colors.green.withValues(alpha: 0.05);
    } else if (game.title.toLowerCase().contains('elden') ||
        game.title.toLowerCase().contains('dark')) {
      cardBgColor = Colors.purple.withValues(alpha: 0.05);
    } else if (game.title.toLowerCase().contains('god') ||
        game.platform.value.startsWith('ps')) {
      cardBgColor = const Color(0xFF0D47A1).withValues(alpha: 0.2);
    }

    return GestureDetector(
      onTapDown: (_) {
        // PREFETCH: Start loading game details before the user lifts their finger
        ref.read(gameRepositoryProvider).getGameById(game.id);
      },
      onTap: () => context.push('/game/${game.id}'),
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
                    color: cardBgColor,
                    child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                        ? RepaintBoundary(
                            child: CachedNetworkImage(
                              imageUrl: game.coverUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 250,
                              placeholder: (context, url) => Container(color: cardBgColor),
                              errorWidget: (context, url, error) => Icon(
                                Icons.videogame_asset,
                                size: 40,
                                color: mutedTextColor,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.videogame_asset,
                            size: 40,
                            color: mutedTextColor,
                          ),
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
                            Text(
                              game.condition.label,
                              style: TextStyle(color: mutedTextColor, fontSize: 12),
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
    );
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
            builder: (context) => AddGameModal(initialPlatform: platformFilter),
          );
        },
      ),
    );
  }
}
