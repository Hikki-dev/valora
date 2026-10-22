import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/currency_provider.dart';
import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../models/game.dart';
import '../../models/price_data.dart';
import '../../repositories/game_repository.dart';
import '../../services/price_service.dart';
import '../../widgets/comic.dart';
import '../../widgets/game_cover.dart';
import 'edit_game_sheet.dart';
import 'widgets/historical_price_chart.dart';

// Loads a single game.
final gameDetailProvider = FutureProvider.autoDispose.family<Game?, String>(
  (ref, gameId) => ref.read(gameRepositoryProvider).getGameById(gameId),
);

// Live PriceData for a game (uses the cached columns while they are fresh).
final gamePricesProvider =
    FutureProvider.autoDispose.family<PriceData?, String>(
  (ref, gameId) async {
    final game = await ref.watch(gameDetailProvider(gameId).future);
    if (game == null) return null;

    // Let the screen paint first, then fetch prices: opening a game feels instant.
    await Future.delayed(const Duration(milliseconds: 150));

    if (!game.isPriceCacheStale) {
      return PriceData(
        loosePrice: game.priceLoose,
        cibPrice: game.priceComplete,
        newPrice: game.priceNew,
        digitalPrice: game.priceDigital,
        source: game.source ?? 'cache',
      );
    }
    return ref.read(priceServiceProvider).fetchPrices(game);
  },
);

final gameHistoryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, gameId) => ref.read(gameRepositoryProvider).getPriceHistory(gameId),
);

const double _kDesktop = 1000;

/// What the user's own copy is worth. Digital = the store price; physical =
/// the price for the condition they own. Falls back to the stored valuation.
double? _valueFor(Game g, PriceData? pd) => g.platform.isDigital
    ? (pd?.digitalPrice ?? pd?.currentPrice ?? g.activeMarketValue)
    : (pd?.priceForCondition(g.condition) ?? g.activeMarketValue);

String _conditionName(GameCondition c) {
  switch (c) {
    case GameCondition.loose:
      return 'Game only';
    case GameCondition.cib:
    case GameCondition.boxed:
      return 'Complete (box + manual)';
    case GameCondition.new_:
      return 'Sealed';
  }
}

Color _platformTint(AppPlatform p) {
  if (p.isPlayStation) return const Color(0xFF2F6BFF);
  if (p == AppPlatform.steam) return const Color(0xFF66C0F4);
  if (p == AppPlatform.nintendo) return const Color(0xFFE60012);
  return const Color(0xFF8A8AA0);
}

void _toast(BuildContext context, String message, {SnackBarAction? action}) {
  final t = VTokens.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.text,
      shape: Border.all(color: t.line, width: 2),
      duration: const Duration(seconds: 5),
      content: Text(message, style: VText.body(14, t.bg)),
      action: action,
    ));
}

class GameDetailView extends ConsumerWidget {
  final String gameId;
  const GameDetailView({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final async = ref.watch(gameDetailProvider(gameId));
    return Scaffold(
      backgroundColor: t.bg,
      body: async.when(
        loading: () => const _Skeleton(),
        error: (e, _) => _Message(
          title: 'Couldn’t load this game',
          body: 'Check your connection and try again.',
          action: 'Retry',
          onAction: () => ref.invalidate(gameDetailProvider(gameId)),
        ),
        data: (game) => game == null
            ? _Message(
                title: 'Game not found',
                body: 'It may have been removed from your library.',
                action: 'Back to library',
                onAction: () => context.go('/collections'),
              )
            : _Detail(game: game),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.game});
  final Game game;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _refreshing = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/collections');
    }
  }

  Future<void> _edit() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGameSheet(game: widget.game),
    );
    if (!mounted) return;
    final id = widget.game.id;
    ref.invalidate(gameDetailProvider(id));
    ref.invalidate(gamePricesProvider(id));
    ref.invalidate(gameHistoryProvider(id));
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final id = widget.game.id;
    setState(() => _refreshing = true);
    try {
      await ref.read(priceServiceProvider).refreshGameMetadata(widget.game);
      if (!mounted) return;
      ref.invalidate(gameDetailProvider(id));
      ref.invalidate(gamePricesProvider(id));
      ref.invalidate(gameHistoryProvider(id));
      ref.invalidate(libraryStreamProvider);
    } catch (_) {
      if (mounted) {
        _toast(context, 'Couldn’t refresh prices. Try again in a moment.');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Hides the game right away, then deletes after the UNDO window closes.
  void _remove() {
    final game = widget.game;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final t = VTokens.of(context);
    final repo = ref.read(gameRepositoryProvider);
    final pending = container.read(pendingDeletesProvider.notifier);

    pending.add(game.id);
    _back();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.text,
        shape: Border.all(color: t.line, width: 2),
        duration: const Duration(seconds: 5),
        content: Text('${game.title} removed', style: VText.body(14, t.bg)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: t.money,
          onPressed: () {},
        ),
      ))
          .closed
          .then((reason) async {
        if (reason == SnackBarClosedReason.action) {
          pending.remove(game.id);
          return;
        }
        try {
          await repo.deleteGame(game.id, game.userId);
          container.invalidate(allGamesProvider);
        } catch (_) {
          // Delete failed: bring the game back rather than lying about it.
        } finally {
          container.invalidate(libraryStreamProvider);
          pending.remove(game.id);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final id = game.id;
    final currency = ref.watch(currencyProvider);
    final prices = ref.watch(gamePricesProvider(id));
    final history = ref.watch(gameHistoryProvider(id));
    final isDesktop = MediaQuery.sizeOf(context).width >= _kDesktop;

    final pd = prices.value;
    final value = _valueFor(game, pd);
    final loadingPrices = prices.isLoading && pd == null;

    final sections = <Widget>[
      _ValueCard(
        game: game,
        value: value,
        source: pd?.source ?? game.source,
        loading: loadingPrices,
        refreshing: _refreshing,
        onRefresh: _refresh,
        currency: currency,
      ),
      history.when(
        data: (h) => HistoricalPriceChart(game: game, history: h),
        loading: () => const _PanelSkeleton(height: 250),
        error: (_, __) => const SizedBox.shrink(),
      ),
      _Conditions(
          game: game, prices: pd, loading: loadingPrices, currency: currency),
      _Investment(game: game, value: value, currency: currency),
      if ((game.notes ?? '').trim().isNotEmpty) _Notes(text: game.notes!),
    ];

    final body = isDesktop
        ? _desktop(context, game, value, sections)
        : _phone(context, game, value, sections);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: VTokens.of(context).onMoney,
      backgroundColor: VTokens.of(context).money,
      child: body,
    );
  }

  Widget _phone(
      BuildContext context, Game game, double? value, List<Widget> sections) {
    final t = VTokens.of(context);
    final tint = _platformTint(game.platform);
    final top = MediaQuery.paddingOf(context).top;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150 + top,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                        color:
                            Color.alphaBlend(tint.withValues(alpha: 0.42), t.surface2)),
                    CustomPaint(
                        painter: RaysPainter(
                            color: t.rays, origin: const Offset(0.75, 0.6))),
                    CustomPaint(
                        painter: HalftonePainter(color: t.dots, spacing: 8)),
                    Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(height: 2, color: t.line)),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconBtn(
                              icon: Icons.arrow_back,
                              label: 'Back',
                              onTap: _back),
                          const Spacer(),
                          _IconBtn(
                              icon: Icons.edit_outlined,
                              label: 'Edit game',
                              onTap: _edit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      height: 94,
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 150,
                        maxHeight: 150,
                        child: Transform.translate(
                          offset: const Offset(0, -56),
                          child: _CoverCard(game: game, width: 112),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _TitleBlock(game: game, value: value),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverList.separated(
            itemCount: sections.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (_, i) => i < sections.length
                ? _reveal(context, sections[i], i)
                : _reveal(context, _RemoveButton(onTap: _remove), i),
          ),
        ),
      ],
    );
  }

  Widget _desktop(
      BuildContext context, Game game, double? value, List<Widget> sections) {
    final t = VTokens.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      PressableBox(
                        onTap: _back,
                        semanticLabel: 'Back to library',
                        shadowOffset: 3,
                        minHeight: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.arrow_back, size: 18, color: t.text),
                          const SizedBox(width: 8),
                          Text('Library',
                              style: VText.body(14, t.text,
                                  weight: FontWeight.w900)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CoverCard(game: game, width: 300),
                              const SizedBox(height: 18),
                              PressableBox(
                                onTap: _edit,
                                color: t.money,
                                semanticLabel: 'Edit game',
                                child: Text('Edit details',
                                    style: VText.body(14, t.onMoney,
                                        weight: FontWeight.w900)),
                              ),
                              const SizedBox(height: 14),
                              _RemoveButton(onTap: _remove),
                            ],
                          ),
                        ),
                        const SizedBox(width: 36),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TitleBlock(game: game, value: value, large: true),
                              const SizedBox(height: 22),
                              for (var i = 0; i < sections.length; i++) ...[
                                if (i > 0) const SizedBox(height: 18),
                                _reveal(context, sections[i], i),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Staggered fade/slide for the first few sections only; respects reduced motion.
Widget _reveal(BuildContext context, Widget child, int i) {
  if (MediaQuery.disableAnimationsOf(context) || i > 4) return child;
  return child
      .animate()
      .fadeIn(delay: (50 * i).ms, duration: 260.ms)
      .slideY(begin: 0.04, end: 0, delay: (50 * i).ms, duration: 260.ms);
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return SizedBox(
      height: 44,
      child: PressableBox(
        onTap: onTap,
        semanticLabel: label,
        shadowOffset: 3,
        minHeight: 44,
        padding: EdgeInsets.zero,
        child: SizedBox(width: 42, child: Icon(icon, size: 22, color: t.text)),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.game, required this.width});
  final Game game;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      width: width,
      height: width * 4 / 3,
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border.all(color: t.line, width: 2),
        boxShadow: [
          BoxShadow(color: t.money, offset: const Offset(5, 5)),
          BoxShadow(color: t.shadow, offset: const Offset(7, 7)),
        ],
      ),
      child: GameCover(game: game, cacheWidth: (width * 2).round()),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.game, required this.value, this.large = false});
  final Game game;
  final double? value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          _Tag(game.platform.label, bg: t.surface2, fg: t.text),
          if (value != null)
            _Tag('RANK ${valueRank(value!)}', bg: t.money, fg: t.onMoney),
        ]),
        const SizedBox(height: 10),
        Text(game.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: VText.display(large ? 34 : 22, t.text)
                .copyWith(height: 1.12)),
        const SizedBox(height: 8),
        Text(
          [
            if (game.releaseYear != null) '${game.releaseYear}',
            if ((game.publisher ?? '').isNotEmpty) game.publisher!,
            if ((game.genre ?? '').isNotEmpty) game.genre!,
          ].join(' · '),
          style: VText.body(13, t.muted, weight: FontWeight.w500),
        ),
        if (game.platform.isPhysical) ...[
          const SizedBox(height: 4),
          Text('Your copy: ${_conditionName(game.condition)}',
              style: VText.body(13, t.text, weight: FontWeight.w700)),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.bg, required this.fg});
  final String text;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, border: Border.all(color: t.line, width: 2)),
      child: Text(text, style: VText.label(12, fg, spacing: 1)),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.game,
    required this.value,
    required this.source,
    required this.loading,
    required this.refreshing,
    required this.onRefresh,
    required this.currency,
  });

  final Game game;
  final double? value;
  final String? source;
  final bool loading, refreshing;
  final VoidCallback onRefresh;
  final CurrencyState currency;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final fetched = game.fetchedAt;
    final stale = game.isPriceCacheStale;
    final age = fetched == null ? 'never checked' : 'checked ${timeAgo(fetched)}';

    return HardBox(
      color: t.money,
      shadowOffset: 5,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CURRENT VALUE', style: VText.label(12, t.onMoney, spacing: 2)),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              loading ? '···' : currency.formatOrDash(value),
              key: ValueKey(loading ? 'l' : value),
              style: VText.display(44, t.onMoney),
            ),
          ),
          const SizedBox(height: 8),
          if (value == null && !loading)
            Text(
                'No market price found yet. Valora shows a dash instead of guessing.',
                style: VText.body(13, t.onMoney, weight: FontWeight.w500))
          else
            Text(
              '${_sourceName(source)} · $age',
              style: VText.body(13, t.onMoney, weight: FontWeight.w700),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stale ? t.lossBg : t.gainBg,
                  border: Border.all(color: kInk, width: 2),
                ),
                child: Text(stale ? 'OUT OF DATE' : 'FRESH',
                    style: VText.label(12, stale ? t.lossInk : t.gainInk,
                        spacing: 1)),
              ),
              const Spacer(),
              PressableBox(
                onTap: refreshing ? null : onRefresh,
                color: t.surface,
                shadowColor: kInk,
                semanticLabel: 'Refresh price',
                shadowOffset: 3,
                minHeight: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: refreshing
                        ? CircularProgressIndicator(
                            strokeWidth: 2.5, color: t.text)
                        : Icon(Icons.refresh, size: 16, color: t.text),
                  ),
                  const SizedBox(width: 8),
                  Text(refreshing ? 'Checking…' : 'Refresh',
                      style: VText.body(13, t.text, weight: FontWeight.w900)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _sourceName(String? s) {
    if (s == null || s.isEmpty || s == 'cache') return 'Saved price';
    final l = s.toLowerCase();
    if (l.contains('pricecharting')) return 'PriceCharting';
    if (l.contains('steam')) return 'Steam';
    if (l.contains('ebay')) return 'eBay';
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _Conditions extends StatelessWidget {
  const _Conditions({
    required this.game,
    required this.prices,
    required this.loading,
    required this.currency,
  });

  final Game game;
  final PriceData? prices;
  final bool loading;
  final CurrencyState currency;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final cards = game.platform.isDigital
        ? [
            _CondCard(
                title: 'Store price',
                hint: 'Digital copy',
                price: prices?.digitalPrice ?? prices?.currentPrice ?? game.activeMarketValue,
                mine: true,
                loading: loading,
                currency: currency),
          ]
        : [
            _CondCard(
                title: 'Game only',
                hint: 'Disc or cart',
                price: prices?.loosePrice,
                mine: game.condition == GameCondition.loose,
                loading: loading,
                currency: currency),
            _CondCard(
                title: 'Complete',
                hint: 'Box + manual',
                price: prices?.cibPrice,
                mine: game.condition == GameCondition.cib ||
                    game.condition == GameCondition.boxed,
                loading: loading,
                currency: currency),
            _CondCard(
                title: 'Sealed',
                hint: 'Never opened',
                price: prices?.newPrice,
                mine: game.condition == GameCondition.new_,
                loading: loading,
                currency: currency),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VALUE BY CONDITION', style: VText.label(12, t.muted)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final narrow = c.maxWidth < 380 && cards.length > 1;
          if (narrow) {
            return Column(children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CondCard extends StatelessWidget {
  const _CondCard({
    required this.title,
    required this.hint,
    required this.price,
    required this.mine,
    required this.loading,
    required this.currency,
  });

  final String title, hint;
  final double? price;
  final bool mine, loading;
  final CurrencyState currency;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return HardBox(
      color: mine ? t.surface : t.surface2,
      shadowOffset: mine ? 4 : 0,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: VText.body(14, t.text, weight: FontWeight.w900))),
            if (mine)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                color: t.money,
                child: Text('YOURS', style: VText.label(10, t.onMoney, spacing: 1)),
              ),
          ]),
          Text(hint, style: VText.body(12, t.muted, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            loading ? '···' : currency.formatOrDash(price),
            style: VText.display(
                20, price == null && !loading ? t.muted : (mine ? t.moneyText : t.text)),
          ),
        ],
      ),
    );
  }
}

class _Investment extends StatelessWidget {
  const _Investment(
      {required this.game, required this.value, required this.currency});
  final Game game;
  final double? value;
  final CurrencyState currency;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final paid = game.purchasePrice;
    if (paid == null) {
      return HardBox(
        color: t.surface2,
        shadowOffset: 0,
        padding: const EdgeInsets.all(14),
        child: Text(
            'Add what you paid (Edit) to see your profit or loss on this game.',
            style: VText.body(13, t.muted, weight: FontWeight.w500)),
      );
    }
    final diff = value == null ? null : value! - paid;
    final gain = (diff ?? 0) >= 0;
    final pct = (diff == null || paid <= 0) ? null : diff / paid * 100;

    Widget cell(String label, String text, {Color? bg, Color? fg}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: bg ?? Colors.transparent,
                border: Border.all(color: bg == null ? t.soft : t.line, width: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: VText.label(11, fg ?? t.muted, spacing: 1)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(text, style: VText.display(17, fg ?? t.text)),
                ),
              ],
            ),
          ),
        );

    return HardBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR INVESTMENT', style: VText.label(12, t.muted)),
          const SizedBox(height: 10),
          Row(children: [
            cell('PAID', currency.format(paid)),
            const SizedBox(width: 8),
            cell('WORTH', currency.formatOrDash(value)),
            const SizedBox(width: 8),
            cell(
              gain ? 'PROFIT' : 'LOSS',
              diff == null
                  ? '—'
                  : '${gain ? '+' : '-'}${currency.format(diff.abs())}',
              bg: diff == null ? null : (gain ? t.gainBg : t.lossBg),
              fg: diff == null ? null : (gain ? t.gainInk : t.lossInk),
            ),
          ]),
          if (pct != null) ...[
            const SizedBox(height: 8),
            Text(
                '${gain ? 'Up' : 'Down'} ${pct.abs().toStringAsFixed(0)}% since you bought it.',
                style: VText.body(12, t.muted, weight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOTES', style: VText.label(12, t.muted)),
        const SizedBox(height: 8),
        Text(text, style: VText.body(14, t.text, weight: FontWeight.w500)),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return PressableBox(
      onTap: onTap,
      shadowOffset: 0,
      semanticLabel: 'Remove from library',
      color: Colors.transparent,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.delete_outline, size: 18, color: t.danger),
        const SizedBox(width: 8),
        Text('Remove from library',
            style: VText.body(14, t.danger, weight: FontWeight.w900)),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.title,
      required this.body,
      required this.action,
      required this.onAction});
  final String title, body, action;
  final VoidCallback onAction;

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
                style: VText.display(22, t.text)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: VText.body(14, t.muted, weight: FontWeight.w500)),
            const SizedBox(height: 20),
            PressableBox(
              onTap: onAction,
              color: t.money,
              child: Text(action,
                  style: VText.body(14, t.onMoney, weight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelSkeleton extends StatelessWidget {
  const _PanelSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.soft,
      child: Container(height: height, color: Colors.white),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    Widget block(double h, {double? w}) =>
        Container(height: h, width: w, color: Colors.white);
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.soft,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(150 + MediaQuery.paddingOf(context).top),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(28, w: 220),
                  const SizedBox(height: 10),
                  block(16, w: 140),
                  const SizedBox(height: 28),
                  block(150),
                  const SizedBox(height: 18),
                  block(220),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
