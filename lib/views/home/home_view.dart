import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/cache_manager.dart';
import '../../core/currency_provider.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../services/price_service.dart';
import '../../services/share_service.dart';
import '../../services/update_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/comic.dart';
import '../collections/add_game_modal.dart';
import '../collections/library_sync_view.dart';
import '../onboarding/onboarding_content.dart';
import '../onboarding/onboarding_panel.dart';
import 'widgets/collection_snapshot.dart';
import 'widgets/valuation_chart.dart';

/// One GitHub release lookup per app session (was: one per HomeView rebuild,
/// which burns the 60 req/h unauthenticated GitHub rate limit).
final updateInfoProvider =
    FutureProvider<UpdateInfo?>((ref) => UpdateService().checkForUpdate());

const double _kDesktopBreakpoint = 1000;

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final isLoading =
        ref.watch(homeControllerProvider.select<bool>((s) => s.isLoading));
    final isDesktop = MediaQuery.sizeOf(context).width >= _kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLoading
                  ? _HomeSkeleton(
                      key: const ValueKey('skeleton'), isDesktop: isDesktop)
                  : _Dashboard(
                      key: const ValueKey('dashboard'), isDesktop: isDesktop),
            ),
          ),
          // Onboarding panel (slides in from the right)
          Consumer(
            builder: (context, ref, _) {
              final onboardingState = ref.watch(onboardingControllerProvider);
              if (!onboardingState.shouldShow) return const SizedBox.shrink();
              final contents = onboardingState.isFull
                  ? OnboardingContent.features
                  : OnboardingContent.changelog;
              return Align(
                alignment: Alignment.centerRight,
                child: OnboardingPanel(contents: contents)
                    .animate()
                    .slideX(
                        begin: 1,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic)
                    .fadeIn(),
              );
            },
          ),
          if (!isDesktop) const _UpdateBanner(),
        ],
      ),
    );
  }
}

/// "New version available" banner (Android builds only; the service returns null on web).
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final info = ref.watch(updateInfoProvider).valueOrNull;
    if (info == null || !info.isUpdateAvailable) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: PressableBox(
        color: t.accent,
        shadowColor: t.shadow,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        semanticLabel: 'Update to version ${info.latestVersion}',
        onTap: () async {
          final url = Uri.parse(info.downloadUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: t.onAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Version ${info.latestVersion} is ready',
                  style: VText.body(14, t.onAccent, weight: FontWeight.w900)),
            ),
            Text('UPDATE',
                style: VText.body(13, t.onAccent, weight: FontWeight.w900)),
          ],
        ),
      )
          .animate()
          .slideY(
              begin: 1.5, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
          .fadeIn(),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({super.key, required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final pad = isDesktop ? 32.0 : 20.0;

    final hero = _HeroCard(isDesktop: isDesktop);
    const quick = _QuickActions();
    const platforms = _PlatformList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, isDesktop ? 28 : 12, pad, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop) const _MobileHeader(),
              if (isDesktop) ...[
                Text('おかえり · WELCOME BACK',
                    style: VText.label(14, t.muted, spacing: 2.2)),
                const SizedBox(height: 2),
                Text('Your collection', style: VText.display(34, t.text)),
                const SizedBox(height: 22),
              ],
              _Reveal(
                index: 0,
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: hero),
                          const SizedBox(width: 28),
                          const Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                quick,
                                SizedBox(height: 20),
                                platforms,
                              ],
                            ),
                          ),
                        ],
                      )
                    : hero,
              ),
              if (!isDesktop) ...[
                const SizedBox(height: 18),
                const _Reveal(index: 1, child: quick),
              ],
              const SizedBox(height: 28),
              _Reveal(index: 2, child: _CrownJewels(isDesktop: isDesktop)),
              const _Reveal(index: 3, child: _ProfitStrip()),
              const _Reveal(index: 4, child: _RecentlyAdded()),
              if (!isDesktop) ...[
                const SizedBox(height: 8),
                const _Reveal(index: 5, child: platforms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One-time fade + rise for the first screenful (cap the stagger so nothing waits).
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: 380.ms, delay: (index.clamp(0, 6) * 55).ms)
        .slideY(
            begin: 0.05, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}

class _MobileHeader extends ConsumerWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLkr = ref.watch(currencyProvider).currency == AppCurrency.lkr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text('VALORA', style: VText.display(22, t.text, spacing: 2.2)),
          const Spacer(),
          VSegmented(
            semanticLabel: 'Currency',
            options: const ['USD', 'LKR'],
            index: isLkr ? 1 : 0,
            onChanged: (i) {
              if ((i == 1) != isLkr) {
                ref.read(currencyProvider.notifier).toggleCurrency();
              }
            },
          ),
          const SizedBox(width: 8),
          PressableBox(
            padding: EdgeInsets.zero,
            minHeight: 44,
            shadowOffset: 0,
            semanticLabel: 'Switch theme',
            onTap: () => ref.read(themeProvider.notifier).toggle(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (c, a) => RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(a),
                    child: FadeTransition(opacity: a, child: c)),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                  color: t.text,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 2) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _HeroCard extends ConsumerStatefulWidget {
  const _HeroCard({required this.isDesktop});
  final bool isDesktop;

  @override
  ConsumerState<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends ConsumerState<_HeroCard> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final games = ref.read(libraryStreamProvider).valueOrNull ?? <Game>[];
      final stale = games.where((g) => g.isPriceCacheStale).toList();
      if (stale.isNotEmpty) {
        await ref.read(priceServiceProvider).fetchPricesBatch(stale);
        ref.invalidate(libraryStreamProvider);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _share() async {
    final games = await ref.read(allGamesProvider.future);
    final sorted = List<Game>.from(games)
      ..sort((a, b) =>
          (b.activeMarketValue ?? 0).compareTo(a.activeMarketValue ?? 0));
    if (!mounted) return;
    final state = ref.read(homeControllerProvider);
    final currency = ref.read(currencyProvider);
    await ShareService().shareSnapshot(
      context,
      CollectionSnapshotWidget(
        top10Games: sorted.take(10).toList(),
        totalValuation: state.totalValuation,
        totalGames: state.totalGames,
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final state = ref.watch(homeControllerProvider);
    final currency = ref.watch(currencyProvider);
    final games = ref.watch(libraryStreamProvider).valueOrNull ?? <Game>[];
    final hide = state.hidePricing;
    final delta = state.weeklyDelta;
    final isGain = delta >= 0;
    final big = widget.isDesktop;

    DateTime? latest;
    for (final g in games) {
      final f = g.fetchedAt;
      if (f != null && (latest == null || f.isAfter(latest))) latest = f;
    }
    final updated = _refreshing
        ? 'Checking prices…'
        : latest == null
            ? 'No prices yet'
            : 'Prices updated ${_ago(latest)}';

    return HardBox(
      color: t.money,
      shadowOffset: big ? 8 : 6,
      shadowColor: t.shadow,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RaysPainter(
                    color: t.onMoney.withValues(alpha: 0.07),
                    origin: const Offset(0.15, 0.5)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  big ? 24 : 18, big ? 22 : 16, big ? 24 : 18, big ? 18 : 12),
              child: LayoutBuilder(builder: (context, c) {
                final showHero =
                    isGain && state.totalValuation > 0 && c.maxWidth > 290;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('総資産 · TOTAL VALUE',
                              style: VText.label(big ? 14 : 13, t.onMoney,
                                  spacing: 2)),
                        ),
                        _HeroIcon(
                          icon: Icons.ios_share_rounded,
                          label: 'Share a snapshot of your collection',
                          onTap: _share,
                          color: t.onMoney,
                        ),
                        _HeroIcon(
                          icon: hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          label: hide ? 'Show values' : 'Hide values',
                          onTap: () => ref
                              .read(homeControllerProvider.notifier)
                              .togglePricingVisibility(),
                          color: t.onMoney,
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: showHero ? 70 : 0),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: state.totalValuation),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                hide ? '••••••' : currency.format(v),
                                style: VText.display(big ? 60 : 44, t.onMoney),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                        if (showHero)
                          Positioned(
                            right: 0,
                            top: -4,
                            child: const _HeroCheer()
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 300.ms)
                                .scale(
                                    begin: const Offset(0.7, 0.7),
                                    delay: 500.ms,
                                    duration: 350.ms,
                                    curve: Curves.easeOutBack),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isGain ? t.gainBg : t.lossBg,
                            border: Border.all(color: t.line, width: 2),
                          ),
                          child: Text(
                            hide
                                ? '${isGain ? '▲' : '▼'} •••• this week'
                                : '${isGain ? '▲' : '▼'} ${currency.format(delta.abs())} this week',
                            style: VText.body(
                                13, isGain ? t.gainInk : t.lossInk,
                                weight: FontWeight.w900),
                          ),
                        ),
                        Text('${state.totalGames} games',
                            style: VText.body(13, t.onMoney)),
                      ],
                    ),
                    if (state.valueHistory.length > 1) ...[
                      const SizedBox(height: 6),
                      ValuationChart(
                        history: state.valueHistory,
                        hidePricing: hide,
                        lineColor: t.onMoney,
                        height: big ? 170 : 110,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(updated, style: VText.body(13, t.onMoney)),
                        ),
                        Semantics(
                          button: true,
                          label: 'Refresh prices',
                          child: InkWell(
                            onTap: _refresh,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _refreshing
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: t.onMoney),
                                        )
                                      : Icon(Icons.refresh_rounded,
                                          size: 18, color: t.onMoney),
                                  const SizedBox(width: 6),
                                  Text('Refresh prices',
                                      style: VText.body(13, t.onMoney,
                                          weight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

/// The hero cheering next to an "UP!" burst: shown while your collection is gaining.
class _HeroCheer extends StatelessWidget {
  const _HeroCheer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 66,
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -2,
            top: 0,
            child: StarburstBadge(
              text: 'UP!',
              size: 40,
              textSize: 11,
              fill: Color(0xFFFF5C8A),
              textColor: Color(0xFFF4EFE6),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: HeroFigure(width: 46, armEnd: Offset(38, 10)),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  void _addGame(BuildContext context, {bool scan = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGameModal(autoScan: scan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    Widget action(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: PressableBox(
            shadowOffset: 3,
            minHeight: 76,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            semanticLabel: label,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: t.text),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    style: VText.body(13, t.text, weight: FontWeight.w900)),
              ],
            ),
          ),
        );

    return HardBox(
      shadowOffset: 0,
      borderWidth: 0,
      color: Colors.transparent,
      child: Row(
        children: [
          action(Icons.add_rounded, 'Add game', () => _addGame(context)),
          const SizedBox(width: 10),
          action(Icons.qr_code_scanner_rounded, 'Scan barcode',
              () => _addGame(context, scan: true)),
          const SizedBox(width: 10),
          action(
            Icons.download_rounded,
            'Import Steam',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibrarySyncView()),
            ),
          ),
        ],
      ),
    );
  }
}

String _rank(double v) => v >= 100 ? 'S' : (v >= 40 ? 'A' : 'B');

class _Cover extends StatelessWidget {
  const _Cover({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final fallback = Container(
      color: t.surface2,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Text(game.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: VText.body(11, t.muted)),
    );
    final url = game.coverUrl;
    if (url == null || url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: gameCoverCacheManager,
      memCacheWidth: 300,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(color: t.surface2),
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _CrownJewels extends ConsumerWidget {
  const _CrownJewels({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final games = ref.watch(libraryStreamProvider).valueOrNull ?? <Game>[];
    final currency = ref.watch(currencyProvider);
    final hide =
        ref.watch(homeControllerProvider.select<bool>((s) => s.hidePricing));

    final priced = games.where((g) => (g.activeMarketValue ?? 0) > 0).toList()
      ..sort((a, b) => b.activeMarketValue!.compareTo(a.activeMarketValue!));
    final count = isDesktop ? 5 : 3;
    final top = priced.take(count).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Most valuable',
                    style: VText.display(isDesktop ? 20 : 16, t.text)),
              ),
              TextButton(
                onPressed: () => context.push('/insights'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: Text('All insights →',
                    style: VText.body(13, t.accent, weight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) SizedBox(width: isDesktop ? 20 : 12),
                Expanded(
                  child: i < top.length
                      ? _CrownCard(
                          game: top[i],
                          price: hide
                              ? '••••'
                              : currency.formatOrDash(top[i].activeMarketValue),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CrownCard extends StatelessWidget {
  const _CrownCard({required this.game, required this.price});
  final Game game;
  final String price;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final rank = _rank(game.activeMarketValue ?? 0);
    return PressableBox(
      shadowOffset: 0,
      padding: EdgeInsets.zero,
      minHeight: 0,
      color: Colors.transparent,
      semanticLabel: '${game.title}, rank $rank, $price',
      onTap: () => context.push('/game/${game.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              HardBox(
                shadowOffset: 4,
                child:
                    AspectRatio(aspectRatio: 3 / 4, child: _Cover(game: game)),
              ),
              Positioned(
                left: -8,
                top: -8,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank == 'S' ? t.money : t.surface,
                    border: Border.all(color: t.line, width: 2),
                  ),
                  child: Text(rank,
                      style:
                          VText.display(14, rank == 'S' ? t.onMoney : t.text)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(game.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VText.body(12, t.text)),
          Text(price, style: VText.body(15, t.text, weight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ProfitStrip extends ConsumerWidget {
  const _ProfitStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final games = ref.watch(libraryStreamProvider).valueOrNull ?? <Game>[];
    final currency = ref.watch(currencyProvider);
    final hide =
        ref.watch(homeControllerProvider.select<bool>((s) => s.hidePricing));

    // Only games where both what you paid and today's value are known.
    final tracked = games
        .where((g) => g.purchasePrice != null && g.activeMarketValue != null)
        .toList();
    if (tracked.isEmpty) return const SizedBox.shrink();

    final invested = tracked.fold<double>(0, (s, g) => s + g.purchasePrice!);
    final market = tracked.fold<double>(0, (s, g) => s + g.activeMarketValue!);
    final gain = market - invested;
    final isGain = gain >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: HardBox(
        color: isGain ? t.gainBg : t.lossBg,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
                isGain
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 30,
                color: isGain ? t.gainInk : t.lossInk),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROFIT ON ${tracked.length} TRACKED GAMES',
                      style: VText.label(11, isGain ? t.gainInk : t.lossInk)),
                  const SizedBox(height: 2),
                  Text(
                    hide
                        ? '••••'
                        : '${isGain ? '+' : '−'}${currency.format(gain.abs())}',
                    style: VText.display(22, isGain ? t.gainInk : t.lossInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentlyAdded extends ConsumerWidget {
  const _RecentlyAdded();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final games = ref.watch(libraryStreamProvider).valueOrNull ?? <Game>[];
    if (games.isEmpty) return const SizedBox.shrink();
    final recent = games.take(8).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recently added', style: VText.display(16, t.text)),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final g = recent[i];
                return Semantics(
                  button: true,
                  label: g.title,
                  child: GestureDetector(
                    onTap: () => context.push('/game/${g.id}'),
                    child: SizedBox(
                      width: 96,
                      child: HardBox(
                        shadowOffset: 3,
                        child: _Cover(game: g),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformList extends StatelessWidget {
  const _PlatformList();

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('By platform', style: VText.display(16, t.text)),
        const SizedBox(height: 12),
        const _PlatformRow(
          title: 'PlayStation',
          subtitle: 'Discs',
          filter: 'ps_disc',
          color: Color(0xFF3B7BFF),
          icon: FaIcon(FontAwesomeIcons.playstation, size: 22),
        ),
        const _PlatformRow(
          title: 'PSN Digital',
          subtitle: 'Downloads',
          filter: 'psn',
          color: Color(0xFF1FB6D6),
          icon: FaIcon(FontAwesomeIcons.playstation, size: 22),
        ),
        const _PlatformRow(
          title: 'Steam',
          subtitle: 'PC',
          filter: 'steam',
          color: Color(0xFF66C0F4),
          icon: FaIcon(FontAwesomeIcons.steam, size: 22),
        ),
        const _PlatformRow(
          title: 'Epic Games',
          subtitle: 'PC',
          filter: 'epic',
          color: Color(0xFF9AA0A6),
          icon: Icon(Icons.gamepad_rounded, size: 22),
        ),
        const _PlatformRow(
          title: 'Nintendo',
          subtitle: 'Switch',
          filter: 'nintendo',
          color: Color(0xFFD81E5B),
          icon: Icon(Icons.videogame_asset_rounded, size: 22),
        ),
      ],
    );
  }
}

class _PlatformRow extends ConsumerWidget {
  const _PlatformRow({
    required this.title,
    required this.subtitle,
    required this.filter,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String filter;
  final Color color;
  final Widget icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final stats = ref.watch(homeControllerProvider.select<PlatformStat>(
        (s) => s.platformStats[filter] ?? const PlatformStat(0, 0)));
    final hide =
        ref.watch(homeControllerProvider.select<bool>((s) => s.hidePricing));
    final currency = ref.watch(currencyProvider);
    final empty = stats.count == 0;
    final gamesLabel = '${stats.count} ${stats.count == 1 ? 'game' : 'games'}';
    final valueLabel =
        hide || empty ? (empty ? '—' : '••••') : currency.format(stats.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: empty ? 0.6 : 1,
        child: PressableBox(
          shadowOffset: 3,
          padding: EdgeInsets.zero,
          minHeight: 64,
          semanticLabel:
              '$title, $gamesLabel, ${empty ? 'no value yet' : (hide ? 'hidden' : currency.format(stats.value))}',
          onTap: () => context.push('/collections?platform=$filter'),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 8, color: color),
                const SizedBox(width: 14),
                IconTheme(
                  data: IconThemeData(color: t.text),
                  child: DefaultTextStyle.merge(
                      style: TextStyle(color: t.text), child: icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: VText.body(15, t.text,
                                weight: FontWeight.w900)),
                        Text('$gamesLabel · $subtitle',
                            style: VText.body(12, t.muted,
                                weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                Text(valueLabel,
                    style: VText.body(16, t.text, weight: FontWeight.w900)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: t.muted, size: 20),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({super.key, required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    Widget block(double h, {double? w}) =>
        Container(height: h, width: w, color: Colors.white);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      child: Shimmer.fromColors(
        baseColor: t.surface2,
        highlightColor: t.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(24, w: 120),
            const SizedBox(height: 16),
            block(isDesktop ? 230 : 210),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: block(76)),
              const SizedBox(width: 10),
              Expanded(child: block(76)),
              const SizedBox(width: 10),
              Expanded(child: block(76)),
            ]),
            const SizedBox(height: 28),
            block(18, w: 140),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: block(130)),
              const SizedBox(width: 12),
              Expanded(child: block(130)),
              const SizedBox(width: 12),
              Expanded(child: block(130)),
            ]),
            const SizedBox(height: 28),
            for (var i = 0; i < 3; i++) ...[
              block(64),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
