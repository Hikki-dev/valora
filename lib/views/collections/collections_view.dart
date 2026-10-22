import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/currency_provider.dart';
import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../services/price_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/comic.dart';
import '../../widgets/game_cover.dart';
import 'add_game_modal.dart';
import 'game_detail_view.dart';
import '../collections/library_sync_view.dart';

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

enum LibrarySort { value, title, recent }

class LibrarySortNotifier extends Notifier<LibrarySort> {
  @override
  LibrarySort build() => LibrarySort.value;
  void set(LibrarySort v) => state = v;
}

enum LibraryLayout { grid, list }

class LibraryLayoutNotifier extends Notifier<LibraryLayout> {
  @override
  LibraryLayout build() => LibraryLayout.grid;
  void set(LibraryLayout v) => state = v;
}

final selectedSubCategoryProvider =
    NotifierProvider<SelectedSubCategory, String>(
  SelectedSubCategory.new,
);
final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);
final librarySortProvider =
    NotifierProvider<LibrarySortNotifier, LibrarySort>(LibrarySortNotifier.new);
final libraryLayoutProvider =
    NotifierProvider<LibraryLayoutNotifier, LibraryLayout>(
        LibraryLayoutNotifier.new);

final filteredGamesProvider = Provider.family
    .autoDispose<AsyncValue<List<Game>>, String?>((ref, platformFilter) {
  final gamesAsync = ref.watch(libraryStreamProvider);
  final subCategory = ref.watch(selectedSubCategoryProvider);
  final search = ref.watch(searchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(librarySortProvider);

  return gamesAsync.whenData((allGames) {
    var filtered = allGames.where((g) {
      final p = g.platform.value;
      if (platformFilter != null && platformFilter.isNotEmpty) {
        final ok = switch (platformFilter) {
          'playstation' => p.startsWith('ps'),
          'ps_disc' => p == 'ps4_physical' || p == 'ps5_physical',
          'psn' => p == 'ps4_digital' || p == 'ps5_digital',
          _ => p == platformFilter,
        };
        if (!ok) return false;
      }
      if (subCategory == 'PS5' && !p.startsWith('ps5')) return false;
      if (subCategory == 'PS4' && !p.startsWith('ps4')) return false;
      if (search.isNotEmpty && !g.title.toLowerCase().contains(search)) {
        return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case LibrarySort.value:
        filtered.sort((a, b) =>
            (b.activeMarketValue ?? -1).compareTo(a.activeMarketValue ?? -1));
      case LibrarySort.title:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case LibrarySort.recent:
        break; // the stream is already newest-first
    }
    return filtered;
  });
});

const double _kDesktop = 1000;

String _platformTitle(String? f) => switch (f) {
      'playstation' || 'ps_disc' || 'psn' => 'PlayStation',
      'steam' => 'Steam',
      'epic' => 'Epic Games',
      'nintendo' => 'Nintendo',
      _ => 'My Library',
    };

String _chipOf(String? f) => switch (f) {
      'playstation' || 'ps_disc' || 'psn' => 'PlayStation',
      'steam' => 'Steam',
      'epic' => 'Epic',
      'nintendo' => 'Nintendo',
      _ => 'All',
    };

class CollectionsView extends ConsumerWidget {
  final String? platformFilter;

  const CollectionsView({super.key, this.platformFilter});

  void _openAdd(BuildContext context, {bool scan = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGameModal(
        autoScan: scan,
        initialPlatform: platformFilter != null
            ? AppPlatform.fromString(platformFilter!)
            : null,
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref, List<Game> games) async {
    final stale = games.where((g) => g.isPriceCacheStale).toList();
    if (stale.isEmpty) return;
    await ref.read(priceServiceProvider).fetchPricesBatch(stale);
    ref.invalidate(libraryStreamProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final gamesAsync = ref.watch(filteredGamesProvider(platformFilter));
    final layout = ref.watch(libraryLayoutProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktop;
    final pad = isDesktop ? 32.0 : 20.0;
    final libraryEmpty =
        (ref.watch(libraryStreamProvider).valueOrNull ?? const <Game>[])
            .isEmpty;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: t.text,
              backgroundColor: t.money,
              onRefresh: () =>
                  _refresh(ref, gamesAsync.valueOrNull ?? const <Game>[]),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              pad, isDesktop ? 28 : 12, pad, 8),
                          child: _Header(
                            platformFilter: platformFilter,
                            isDesktop: isDesktop,
                            games: gamesAsync.valueOrNull,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...gamesAsync.when(
                    loading: () => [
                      SliverToBoxAdapter(child: _GridSkeleton(pad: pad)),
                    ],
                    error: (e, _) => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _Message(
                          title: 'Couldn’t load your library',
                          body: 'Check your connection and pull down to try again.',
                        ),
                      ),
                    ],
                    data: (games) {
                      if (games.isEmpty) {
                        return [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: libraryEmpty
                                ? _EmptyShelf(
                                    onSearch: () => _openAdd(context),
                                    onScan: () => _openAdd(context, scan: true),
                                    onImport: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const LibrarySyncView()),
                                    ),
                                  )
                                : const _NoMatches(),
                          ),
                        ];
                      }
                      final content = layout == LibraryLayout.list && isDesktop
                          ? SliverList.builder(
                              itemCount: games.length,
                              itemBuilder: (context, i) => _Row(
                                  game: games[i],
                                  index: i,
                                  last: i == games.length - 1),
                            )
                          : SliverGrid.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 210,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.54,
                              ),
                              itemCount: games.length,
                              itemBuilder: (context, i) =>
                                  _GameCard(game: games[i], index: i),
                            );
                      return [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pad,
                            8,
                            pad,
                            isDesktop ? 40 : 110,
                          ),
                          sliver: SliverLayoutBuilder(
                            builder: (context, c) {
                              // Keep content centred on very wide screens.
                              final side = ((c.crossAxisExtent + 2 * pad - 1240) / 2)
                                  .clamp(0.0, 9999.0);
                              return SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: side),
                                sliver: layout == LibraryLayout.list && isDesktop
                                    ? SliverMainAxisGroup(slivers: [
                                        const SliverToBoxAdapter(
                                            child: _RowHeader()),
                                        content,
                                      ])
                                    : content,
                              );
                            },
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            if (!isDesktop)
              Positioned(
                right: 20,
                bottom: 20,
                child: PressableBox(
                  color: t.accent,
                  shadowColor: t.shadow,
                  semanticLabel: 'Add game',
                  minHeight: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  onTap: () => _openAdd(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: t.onAccent, size: 22),
                      const SizedBox(width: 8),
                      Text('Add game',
                          style: VText.body(15, t.onAccent,
                              weight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.platformFilter,
    required this.isDesktop,
    required this.games,
  });

  final String? platformFilter;
  final bool isDesktop;
  final List<Game>? games;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final sort = ref.watch(librarySortProvider);
    final layout = ref.watch(libraryLayoutProvider);
    final sub = ref.watch(selectedSubCategoryProvider);
    final chip = _chipOf(platformFilter);

    final count = games?.length ?? 0;
    final worth = (games ?? const <Game>[])
        .fold<double>(0, (s, g) => s + (g.activeMarketValue ?? 0));

    void go(String name) {
      ref.read(selectedSubCategoryProvider.notifier).set('All');
      final path = switch (name) {
        'PlayStation' => '/collections?platform=playstation',
        'Nintendo' => '/collections?platform=nintendo',
        'Steam' => '/collections?platform=steam',
        'Epic' => '/collections?platform=epic',
        _ => '/collections',
      };
      context.go(path);
    }

    final summary = Text.rich(
      TextSpan(children: [
        TextSpan(
            text: '$count ${count == 1 ? 'game' : 'games'}',
            style: VText.body(13, t.text, weight: FontWeight.w900)),
        TextSpan(
            text: ' · worth ',
            style: VText.body(13, t.muted, weight: FontWeight.w500)),
        TextSpan(
            text: worth > 0 ? currency.format(worth) : '—',
            style: VText.body(13, t.text, weight: FontWeight.w900)),
      ]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CHAPTER 01 · ライブラリ',
            style: VText.label(isDesktop ? 14 : 13, t.muted, spacing: 2.2)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(_platformTitle(platformFilter),
                  style: VText.display(isDesktop ? 34 : 28, t.text)),
            ),
            if (isDesktop) summary,
          ],
        ),
        if (!isDesktop) ...[
          const SizedBox(height: 4),
          summary,
        ],
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: _SearchField()),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final name in const [
                'All',
                'PlayStation',
                'Nintendo',
                'Steam',
                'Epic'
              ]) ...[
                _FilterChip(
                  label: name,
                  selected: chip == name,
                  onTap: () => go(name),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (chip == 'PlayStation') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (final s in const ['All', 'PS5', 'PS4']) ...[
                _FilterChip(
                  label: s == 'All' ? 'All PlayStation' : s,
                  selected: sub == s,
                  small: true,
                  onTap: () =>
                      ref.read(selectedSubCategoryProvider.notifier).set(s),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            PopupMenuButton<LibrarySort>(
              tooltip: 'Sort',
              color: t.surface,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: t.line, width: 2)),
              onSelected: (v) => ref.read(librarySortProvider.notifier).set(v),
              itemBuilder: (_) => [
                for (final s in LibrarySort.values)
                  PopupMenuItem(
                    value: s,
                    child: Text(_sortName(s),
                        style: VText.body(14, t.text,
                            weight: s == sort ? FontWeight.w900 : FontWeight.w500)),
                  ),
              ],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sort: ${_sortName(sort)}',
                        style: VText.body(13, t.text, weight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Icon(Icons.unfold_more_rounded, size: 18, color: t.text),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (isDesktop)
              VSegmented(
                semanticLabel: 'Layout',
                options: const ['Grid', 'List'],
                index: layout == LibraryLayout.grid ? 0 : 1,
                onChanged: (i) => ref
                    .read(libraryLayoutProvider.notifier)
                    .set(i == 0 ? LibraryLayout.grid : LibraryLayout.list),
              ),
          ],
        ),
      ],
    );
  }

  String _sortName(LibrarySort s) => switch (s) {
        LibrarySort.value => 'Value ↓',
        LibrarySort.title => 'A–Z',
        LibrarySort.recent => 'Recent',
      };
}

/// Search with a 200ms debounce so typing doesn't re-filter on every keystroke.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _c = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _c.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200),
        () => ref.read(searchQueryProvider.notifier).set(v));
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return TextField(
      controller: _c,
      onChanged: _changed,
      style: VText.body(16, t.text, weight: FontWeight.w500),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search your library',
        hintStyle: VText.body(16, t.muted, weight: FontWeight.w500),
        prefixIcon: Icon(Icons.search_rounded, color: t.muted),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: Icon(Icons.close_rounded, color: t.text),
                onPressed: () {
                  _c.clear();
                  _changed('');
                },
              ),
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: t.soft, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: t.line, width: 2)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.small = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(minHeight: small ? 36 : 40),
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.text : t.surface,
            border: Border.all(color: selected ? t.text : t.soft, width: 2),
          ),
          child: Text(label,
              style: VText.body(13, selected ? t.bg : t.text,
                  weight: FontWeight.w900)),
        ),
      ),
    );
  }
}

String _meta(Game g) {
  final v = g.activeMarketValue;
  if (v == null) return 'No price yet · tap to add one';
  final parts = <String>[
    g.platform.isDigital ? 'Digital' : g.condition.label,
  ];
  final src = g.source;
  if (src != null && src.isNotEmpty && src != 'unavailable') {
    parts.add(src);
  } else if (g.estimatedValue != null) {
    parts.add('Your estimate');
  }
  if (g.fetchedAt != null) parts.add(timeAgo(g.fetchedAt!));
  return parts.join(' · ');
}

class _GameCard extends ConsumerWidget {
  const _GameCard({required this.game, required this.index});
  final Game game;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final v = game.activeMarketValue;
    final rank = (v != null && v >= 40) ? valueRank(v) : null;
    final noPrice = v == null;

    final card = RepaintBoundary(
      child: PressableBox(
        shadowOffset: 4,
        padding: EdgeInsets.zero,
        minHeight: 0,
        semanticLabel:
            '${game.title}, ${currency.formatOrDash(v)}${rank != null ? ', rank $rank' : ''}',
        // Warm the price provider on touch-down so the detail page opens with data.
        onPressStart: () => ref.read(gamePricesProvider(game.id)),
        onTap: () => context.push('/game/${game.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'game_cover_${game.id}',
                    child: GameCover(game: game),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: t.surface,
                        border: Border.all(color: t.line, width: 2),
                      ),
                      child: Text(game.platform.label.toUpperCase(),
                          style: VText.body(11, t.text, weight: FontWeight.w900)),
                    ),
                  ),
                  if (rank != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank == 'S' ? t.money : t.surface,
                          border: Border.all(color: t.line, width: 2),
                        ),
                        child: Text(rank,
                            style: VText.display(13, rank == 'S' ? t.onMoney : t.text)),
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 2, color: t.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,
                    child: Text(game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VText.body(14, t.text).copyWith(height: 1.25)),
                  ),
                  const SizedBox(height: 2),
                  Text(currency.formatOrDash(v),
                      style: VText.body(18, noPrice ? t.muted : t.text,
                          weight: FontWeight.w900)),
                  const SizedBox(height: 1),
                  SizedBox(
                    height: 30,
                    child: Text(_meta(game),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VText.body(11, noPrice ? t.accent : t.muted,
                                weight: noPrice ? FontWeight.w900 : FontWeight.w500)
                            .copyWith(height: 1.3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Only the first screenful animates in; lazily built cards further down must
    // appear instantly.
    return index < 12
        ? card
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 30).ms)
            .slideY(begin: 0.06, end: 0, duration: 300.ms)
        : card;
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader();

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    TextStyle s() => VText.body(12, t.muted, weight: FontWeight.w900);
    return Container(
      color: t.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: null,
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(flex: 5, child: Text('TITLE', style: s())),
          Expanded(flex: 2, child: Text('CONDITION', style: s())),
          Expanded(flex: 2, child: Text('YOU PAID', style: s())),
          Expanded(flex: 2, child: Text('VALUE', style: s())),
          Expanded(flex: 2, child: Text('PROFIT', style: s())),
          Expanded(flex: 2, child: Text('UPDATED', style: s())),
        ],
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.game, required this.index, required this.last});
  final Game game;
  final int index;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final v = game.activeMarketValue;
    final paid = game.purchasePrice;
    final profit = (v != null && paid != null) ? v - paid : null;

    return RepaintBoundary(
      child: InkWell(
        onTap: () => context.push('/game/${game.id}'),
        hoverColor: t.surface2,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.soft, width: 2)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      border: Border.all(color: t.line, width: 2)),
                  child: GameCover(game: game, cacheWidth: 120),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.body(15, t.text, weight: FontWeight.w900)),
                    Text(game.platform.label,
                        style: VText.body(12, t.muted, weight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                    game.platform.isDigital ? 'Digital' : game.condition.label,
                    style: VText.body(14, t.text)),
              ),
              Expanded(
                flex: 2,
                child: Text(paid == null ? '—' : currency.format(paid),
                    style: VText.body(14, t.text, weight: FontWeight.w500)),
              ),
              Expanded(
                flex: 2,
                child: Text(currency.formatOrDash(v),
                    style: VText.body(16, v == null ? t.muted : t.text,
                        weight: FontWeight.w900)),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: profit == null
                      ? Text('—', style: VText.body(14, t.muted))
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: profit >= 0 ? t.gainBg : t.lossBg,
                            border: Border.all(color: t.line, width: 2),
                          ),
                          child: Text(
                            '${profit >= 0 ? '+' : '−'}${currency.format(profit.abs())}',
                            style: VText.body(13,
                                profit >= 0 ? t.gainInk : t.lossInk,
                                weight: FontWeight.w900),
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                    game.fetchedAt == null ? 'no price yet' : timeAgo(game.fetchedAt!),
                    style: VText.body(13, t.muted, weight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
      child: Shimmer.fromColors(
        baseColor: t.surface2,
        highlightColor: t.surface,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.54,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(color: Colors.white),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: VText.display(20, t.text)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: VText.body(14, t.muted, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends ConsumerWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final q = ref.watch(searchQueryProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            border: Border.all(color: t.soft, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No matches', style: VText.display(20, t.text)),
              const SizedBox(height: 6),
              Text(
                  q.isEmpty
                      ? 'Nothing on your shelf matches these filters.'
                      : 'Nothing on your shelf matches “$q”.',
                  textAlign: TextAlign.center,
                  style: VText.body(14, t.muted, weight: FontWeight.w500)),
              const SizedBox(height: 16),
              PressableBox(
                color: t.money,
                shadowColor: t.shadow,
                shadowOffset: 3,
                onTap: () {
                  ref.read(searchQueryProvider.notifier).set('');
                  ref.read(selectedSubCategoryProvider.notifier).set('All');
                  context.go('/collections');
                },
                child: Text('Clear search & filters',
                    style: VText.body(14, t.onMoney, weight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First-run empty shelf: the hero scratches their head; three quick ways to add games.
class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({
    required this.onSearch,
    required this.onScan,
    required this.onImport,
  });
  final VoidCallback onSearch;
  final VoidCallback onScan;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: HardBox(
            shadowOffset: 5,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HardBox(
                  color: const Color(0xFFFFE08A),
                  shadowOffset: 0,
                  child: SizedBox(
                    height: 110,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                              painter: HalftonePainter(
                                  color: const Color(0x33151215), spacing: 6)),
                        ),
                        const Positioned(
                          left: 28,
                          bottom: 6,
                          child: HeroFigure(width: 58, armEnd: Offset(36, 8)),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          left: 110,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: kInk, width: 2.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Where are all the games?!',
                                style: VText.body(13, kInk, weight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Your shelf is empty', style: VText.display(19, t.text)),
                const SizedBox(height: 4),
                Text('Add your first game, whichever way is quickest:',
                    textAlign: TextAlign.center,
                    style: VText.body(14, t.muted, weight: FontWeight.w500)),
                const SizedBox(height: 16),
                PressableBox(
                  color: t.money,
                  shadowColor: t.shadow,
                  onTap: onSearch,
                  child: Text('Search by title',
                      style: VText.body(15, t.onMoney, weight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PressableBox(
                        shadowOffset: 3,
                        onTap: onScan,
                        child: Text('Scan barcode',
                            style: VText.body(13, t.text, weight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressableBox(
                        shadowOffset: 3,
                        onTap: onImport,
                        child: Text('Import Steam',
                            style: VText.body(13, t.text, weight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
