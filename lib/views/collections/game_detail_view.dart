import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/game.dart';
import '../../models/price_data.dart';
import '../../services/price_service.dart';
import '../../repositories/game_repository.dart';
import '../../core/currency_provider.dart';

// Provider that loads a single game and triggers a background price refresh
final gameDetailProvider = FutureProvider.autoDispose.family<Game?, String>(
  (ref, gameId) async {
    final repo = ref.read(gameRepositoryProvider);
    final game = await repo.getGameById(gameId);
    return game;
  },
);

// Provider that returns the live PriceData for a game (uses cache when fresh)
final gamePricesProvider = FutureProvider.autoDispose.family<PriceData?, String>(
  (ref, gameId) async {
    final game = await ref.watch(gameDetailProvider(gameId).future);
    if (game == null) return null;

    return ref.read(priceServiceProvider).fetchPrices(game);
  },
);

class GameDetailView extends ConsumerWidget {
  final String gameId;
  const GameDetailView({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));
    final pricesAsync = ref.watch(gamePricesProvider(gameId));
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = textColor.withOpacity(0.5);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (game) {
          if (game == null) {
            return const Center(child: Text('Game not found.'));
          }
          return _buildDetail(
            context,
            ref,
            game,
            pricesAsync,
            currency,
            isDark,
            textColor,
            mutedColor,
            cardColor,
          );
        },
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    Game game,
    AsyncValue<PriceData?> pricesAsync,
    CurrencyState currency,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color cardColor,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Custom Robust Header ─────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _GameHeaderDelegate(
            game: game,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/collections');
              }
            },
            onRefresh: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing metadata...'), duration: Duration(seconds: 1)),
              );
              await ref.read(priceServiceProvider).refreshGameMetadata(game);
              ref.invalidate(gameDetailProvider(game.id));
            },
            textColor: textColor,
            mutedColor: mutedColor,
            topPadding: MediaQuery.paddingOf(context).top,
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // eBay MARKET PRICES section
              _SectionLabel(label: 'EBAY MARKET AVG', color: mutedColor),
              const SizedBox(height: 16),
              
              pricesAsync.when(
                loading: () => const _PriceRowsSkeleton(),
                error: (e, _) => Text('Could not load prices.',
                    style: TextStyle(color: mutedColor)),
                data: (prices) => _PriceRows(
                  game: game,
                  prices: prices,
                  currency: currency,
                  cardColor: cardColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  isDark: isDark,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              ),

              const SizedBox(height: 28),

              // YOUR COPY IS VALUED AT card
              pricesAsync.maybeWhen(
                data: (prices) => _ValuationCard(
                  game: game,
                  prices: prices,
                  currency: currency,
                  cardColor: cardColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 28),

              // PROFIT / LOSS section
              pricesAsync.when(
                data: (prices) => game.purchasePrice != null
                    ? _ProfitLossCard(
                        game: game,
                        prices: prices,
                        currency: currency,
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 48),

              // Delete button
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref, game),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Remove from collection',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Game game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Game?'),
        content: Text(
            'Are you sure you want to remove "${game.title}" from your collection?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(gameRepositoryProvider).deleteGame(game.id);
      if (context.mounted) context.pop();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBanner extends ConsumerWidget {
  final Game game;
  final Color textColor;
  final Color mutedColor;

  const _HeroBanner({
    required this.game,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate subtitle: Publisher • Genre • Year
    final List<String> metaParts = [];
    if (game.publisher != null && (game.publisher ?? '').isNotEmpty) {
      metaParts.add(game.publisher!);
    }
    if (game.genre != null && (game.genre ?? '').isNotEmpty) {
      metaParts.add(game.genre!);
    }
    if (game.releaseYear != null) {
      metaParts.add(game.releaseYear.toString());
    }
    final String subtitle = metaParts.join(' • ');

    return Stack(
      children: [
        // Background layer: Dark gradient or cover tint
        Positioned.fill(
          child: game.coverUrl != null && game.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: game.coverUrl!,
                  fit: BoxFit.cover,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(color: Colors.black),
                )
              : Container(color: Colors.black),
        ),
        
        // Main Cover image with Hero transition
        SizedBox(
          height: 280,
          width: double.infinity,
          child: Center(
            child: Hero(
              tag: 'game_cover_${game.id}',
              child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => _FallbackHero(game: game),
                      errorWidget: (context, url, error) => _FallbackHero(game: game),
                    )
                  : _FallbackHero(game: game),
            ),
          ),
        ),

        // Bottom gradient overlay for text legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
                stops: const [0.4, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Title, Subtitle, and Badges
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(label: game.platform.label, primary: true),
                  _Badge(label: game.condition.label),
                  if (game.region != null && (game.region ?? '').isNotEmpty)
                    _Badge(label: game.region!),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                game.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
              
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FallbackHero extends StatelessWidget {
  final Game game;
  const _FallbackHero({required this.game});

  @override
  Widget build(BuildContext context) {
    final colors = _gradientForPlatform(game.platform);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: const Center(
        child: Icon(Icons.videogame_asset, color: Colors.white24, size: 100),
      ),
    );
  }

  List<Color> _gradientForPlatform(AppPlatform p) {
    if (p.isPlayStation) {
      return [const Color(0xFF003087), const Color(0xFF001A4B)];
    }
    if (p == AppPlatform.steam) {
      return [const Color(0xFF1B2838), const Color(0xFF0D1219)];
    }
    if (p == AppPlatform.nintendo) {
      return [const Color(0xFFE60012), const Color(0xFF80000A)];
    }
    return [const Color(0xFF2A2A2A), const Color(0xFF121212)];
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool primary;
  const _Badge({required this.label, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary
            ? (Colors.greenAccent[700] ?? Colors.green).withOpacity(0.15)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary
              ? (Colors.greenAccent[400] ?? Colors.green).withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? Colors.greenAccent[400] : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

// Market price rows (Loose / Complete / New)
class _PriceRows extends StatelessWidget {
  final Game game;
  final PriceData? prices;
  final CurrencyState currency;
  final Color cardColor, textColor, mutedColor;
  final bool isDark;

  const _PriceRows({
    required this.game,
    required this.prices,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (prices == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('No market data available for this title.',
            style: TextStyle(color: mutedColor, fontSize: 14)),
      );
    }

    if (game.platform.isPhysical) {
      return Column(
        children: [
          _PriceRow(
            label: 'Loose',
            sublabel: 'Disc only',
            price: prices?.loosePrice,
            currency: currency,
            cardColor: cardColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isUserCondition: game.condition == GameCondition.loose,
          ),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'Complete',
            sublabel: 'Disc + case + manual',
            price: prices?.cibPrice,
            currency: currency,
            cardColor: cardColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isUserCondition: game.condition == GameCondition.cib || 
                             game.condition == GameCondition.boxed,
          ),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'New & sealed',
            sublabel: 'Factory sealed',
            price: prices?.newPrice,
            currency: currency,
            cardColor: cardColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isUserCondition: game.condition == GameCondition.new_,
          ),
        ],
      );
    }

    return _PriceRow(
      label: 'Store Price',
      sublabel: 'Best digital deal',
      price: prices?.currentPrice,
      currency: currency,
      cardColor: cardColor,
      textColor: textColor,
      mutedColor: mutedColor,
      isUserCondition: true,
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double? price;
  final CurrencyState currency;
  final Color cardColor, textColor, mutedColor;
  final bool isUserCondition;

  const _PriceRow({
    required this.label,
    required this.sublabel,
    required this.price,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.isUserCondition,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor =
        isUserCondition ? Colors.orangeAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUserCondition
              ? Colors.orangeAccent.withOpacity(0.25)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(sublabel, style: TextStyle(color: mutedColor, fontSize: 13)),
            ],
          ),
          Text(
            price != null ? currency.format(price ?? 0.0) : '—',
            style: TextStyle(
              color: priceColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRowsSkeleton extends StatelessWidget {
  const _PriceRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
                child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )),
          ),
        ),
      ),
    );
  }
}

// "Your copy is valued at" card
class _ValuationCard extends StatelessWidget {
  final Game game;
  final PriceData? prices;
  final CurrencyState currency;
  final Color cardColor, textColor, mutedColor;

  const _ValuationCard({
    required this.game,
    required this.prices,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = prices?.priceForCondition(game.condition) ??
        game.activeMarketValue ??
        0.0;
    final source = prices?.source ?? 'Valora';

    String updatedLabel = '';
    if (game.fetchedAt != null) {
      final diff = DateTime.now().difference(game.fetchedAt ?? DateTime.now());
      if (diff.inMinutes < 60) {
        updatedLabel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        updatedLabel = '${diff.inHours}h ago';
      } else {
        updatedLabel = '${diff.inDays}d ago';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your copy is valued at',
              style: TextStyle(
                  color: mutedColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            currency.format(value),
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 40,
              letterSpacing: -1,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (updatedLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Updated $updatedLabel · $source',
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Profit / Loss comparison card
class _ProfitLossCard extends StatelessWidget {
  final Game game;
  final PriceData? prices;
  final CurrencyState currency;
  final Color cardColor, textColor, mutedColor;

  const _ProfitLossCard({
    required this.game,
    required this.prices,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final paid = game.purchasePrice ?? 0.0;
    final valued = prices?.priceForCondition(game.condition) ??
        game.activeMarketValue ??
        paid;
    final diff = valued - paid;
    final isGain = diff >= 0;
    final diffColor = isGain ? (Colors.greenAccent[400] ?? Colors.green) : Colors.redAccent;
    final diffSign = isGain ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'YOUR INVESTMENT', color: mutedColor),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _CompareRow(
                label: 'You paid',
                value: currency.format(paid),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 14),
              _CompareRow(
                label: 'Current market',
                value: currency.format(valued),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net change',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: diffColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      '$diffSign${currency.format(diff.abs())}',
                      style: TextStyle(
                        color: diffColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor, mutedColor;

  const _CompareRow(
      {required this.label,
      required this.value,
      required this.textColor,
      required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: mutedColor, fontSize: 15, fontWeight: FontWeight.w600)),
        Text(value,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}

class _GameHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Game game;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final Color textColor;
  final Color mutedColor;
  final double topPadding;

  _GameHeaderDelegate({
    required this.game,
    required this.onBack,
    required this.onRefresh,
    required this.textColor,
    required this.mutedColor,
    required this.topPadding,
  });

  @override
  double get minExtent => topPadding + kToolbarHeight;

  @override
  double get maxExtent => 280.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double spread = maxExtent - minExtent;
    final double opacity = (1.0 - (shrinkOffset / (spread * 0.5))).clamp(0.0, 1.0);
    final double titleOpacity = (shrinkOffset / spread).clamp(0.0, 1.0);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Background - Hero Banner with parallax/fade
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: _HeroBanner(game: game, textColor: textColor, mutedColor: mutedColor),
            ),
          ),

          // Top Header Bar (Back / Title / Refresh)
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            height: kToolbarHeight,
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.orangeAccent, size: 24),
                  ),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: titleOpacity,
                      child: Text(
                        game.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  ),
                  onPressed: onRefresh,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GameHeaderDelegate oldDelegate) {
    return oldDelegate.game != game || 
           oldDelegate.textColor != textColor ||
           oldDelegate.topPadding != topPadding;
  }
}
