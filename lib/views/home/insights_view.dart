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
import '../../widgets/comic.dart';
import '../../widgets/game_cover.dart';

class InsightsView extends ConsumerWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final async = ref.watch(allGamesProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final pad = isDesktop ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: async.when(
              loading: () => _Skeleton(pad: pad),
              error: (_, __) => Center(
                  child: Text('Couldn’t load insights. Pull to retry.',
                      style: VText.body(14, t.muted))),
              data: (games) {
                // Only games with a real price can be ranked.
                final priced =
                    games.where((g) => (g.activeMarketValue ?? 0) > 0).toList()
                      ..sort((a, b) =>
                          b.activeMarketValue!.compareTo(a.activeMarketValue!));
                if (priced.isEmpty) return _Empty(pad: pad);

                final total =
                    priced.fold<double>(0, (s, g) => s + g.activeMarketValue!);
                final top = priced.take(10).toList();
                final low = priced.length > 10
                    ? priced.reversed.take(10).toList()
                    : <Game>[];
                final unpriced = games.length - priced.length;

                final lists = [
                  _Board(
                      eyebrow: 'MOST VALUABLE',
                      title: 'Crown jewels',
                      games: top,
                      gold: true),
                  if (low.isNotEmpty)
                    _Board(
                        eyebrow: 'LEAST VALUABLE',
                        title: 'Hidden gems',
                        games: low,
                        gold: false),
                ];

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(allGamesProvider.future),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(pad, isDesktop ? 32 : 16, pad, 40),
                    children: [
                      Text('THE NUMBERS', style: VText.label(12, t.muted)),
                      const SizedBox(height: 4),
                      Text('Insights',
                          style: VText.display(isDesktop ? 36 : 28, t.text)),
                      const SizedBox(height: 16),
                      _Summary(
                        total: total,
                        priced: priced.length,
                        unpriced: unpriced,
                        best: priced.first,
                      ),
                      const SizedBox(height: 24),
                      if (isDesktop && lists.length == 2)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: lists[0]),
                            const SizedBox(width: 24),
                            Expanded(child: lists[1]),
                          ],
                        )
                      else
                        for (final l in lists) ...[
                          l,
                          const SizedBox(height: 24),
                        ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary(
      {required this.total,
      required this.priced,
      required this.unpriced,
      required this.best});
  final double total;
  final int priced, unpriced;
  final Game best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final avg = total / priced;

    Widget stat(String label, String value) => Expanded(
          child: HardBox(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: VText.label(11, t.muted, spacing: 1)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: VText.display(18, t.text)),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          stat('PRICED GAMES', '$priced'),
          const SizedBox(width: 12),
          stat('AVERAGE', currency.format(avg)),
          const SizedBox(width: 12),
          stat('TOP GAME', currency.format(best.activeMarketValue!)),
        ]),
        if (unpriced > 0) ...[
          const SizedBox(height: 10),
          Text(
              '$unpriced ${unpriced == 1 ? 'game has' : 'games have'} no market price yet and ${unpriced == 1 ? 'isn’t' : 'aren’t'} ranked.',
              style: VText.body(12, t.muted, weight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board(
      {required this.eyebrow,
      required this.title,
      required this.games,
      required this.gold});
  final String eyebrow, title;
  final List<Game> games;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: VText.label(12, t.muted)),
        const SizedBox(height: 2),
        Text(title, style: VText.display(22, t.text)),
        const SizedBox(height: 12),
        for (var i = 0; i < games.length; i++) ...[
          _Row(game: games[i], rank: i + 1, gold: gold),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.game, required this.rank, required this.gold});
  final Game game;
  final int rank;
  final bool gold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final v = game.activeMarketValue!;

    final row = PressableBox(
      onTap: () => context.push('/game/${game.id}'),
      semanticLabel: '${game.title}, ${currency.format(v)}',
      shadowOffset: 3,
      minHeight: 68,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: VText.display(
                    16, gold && rank <= 3 ? t.moneyText : t.muted)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 54,
            decoration:
                BoxDecoration(border: Border.all(color: t.line, width: 2)),
            child: GameCover(game: game, cacheWidth: 120),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.body(14, t.text, weight: FontWeight.w900)),
                Text(game.platform.label,
                    style: VText.body(12, t.muted, weight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency.format(v), style: VText.display(15, t.text)),
              Text('Rank ${valueRank(v)}',
                  style: VText.label(11, t.muted, spacing: 1)),
            ],
          ),
        ],
      ),
    );

    if (MediaQuery.disableAnimationsOf(context) || rank > 5) return row;
    return row
        .animate()
        .fadeIn(duration: 240.ms, delay: (rank * 40).ms)
        .slideY(begin: 0.04, end: 0, duration: 240.ms, delay: (rank * 40).ms);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(pad + 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nothing to rank yet',
                  textAlign: TextAlign.center,
                  style: VText.display(20, t.text)),
              const SizedBox(height: 8),
              Text(
                  'Add games to your library. Insights ranks the ones with a real market price.',
                  textAlign: TextAlign.center,
                  style: VText.body(14, t.muted, weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.soft,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(pad),
        children: [
          Container(height: 36, width: 180, color: Colors.white),
          const SizedBox(height: 16),
          Container(height: 70, color: Colors.white),
          const SizedBox(height: 24),
          for (var i = 0; i < 5; i++) ...[
            Container(height: 68, color: Colors.white),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
