import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../core/currency_provider.dart';
import '../../models/game.dart';
import '../collections/widgets/game_box_3d.dart';
import '../../repositories/game_repository.dart';
import '../../services/share_service.dart';
import '../../services/update_service.dart';
import 'widgets/collection_snapshot.dart';
import 'widgets/valuation_chart.dart';
import '../onboarding/onboarding_panel.dart';
import '../onboarding/onboarding_content.dart';
import '../../controllers/onboarding_controller.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(homeControllerProvider.select<bool>((s) => s.isLoading));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeToggleIcon = isDark ? Icons.light_mode : Icons.dark_mode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text('Valora',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: textColor)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(themeToggleIcon,
                      color: textColor.withValues(alpha: 0.7)),
                  onPressed: () => ref.read(themeProvider.notifier).toggle(),
                  tooltip: 'Toggle Theme',
                ),
                IconButton(
                  icon: Icon(Icons.currency_exchange,
                      color: textColor.withValues(alpha: 0.7)),
                  onPressed: () =>
                      ref.read(currencyProvider.notifier).toggleCurrency(),
                  tooltip: 'Toggle Currency',
                ),
                IconButton(
                  icon: Icon(Icons.logout,
                      color: textColor.withValues(alpha: 0.7)),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF14141A), const Color(0xFF0A0A0F)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF0F0F5)],
              ),
            ),
            child: SafeArea(
              child: isLoading
                  ? _buildSkeleton(context, ref, isDark, isDesktop)
                  : _buildDashboard(context, ref, isDark, textColor,
                      mutedTextColor, cardColor, isDesktop),
            ),
          ),
          // ONBOARDING PANEL (SLIDING FROM RIGHT)
          Consumer(
            builder: (context, ref, _) {
              final onboardingState = ref.watch(onboardingControllerProvider);
              if (onboardingState.shouldShow) {
                // Determine what content to show
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
              }
              return const SizedBox.shrink();
            },
          ),
          // UPDATE NOTIFICATION
          if (!isDesktop) // Only show on mobile
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: FutureBuilder<UpdateInfo?>(
                future: UpdateService().checkForUpdate(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isUpdateAvailable) {
                    final info = snapshot.data!;
                    return GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(info.downloadUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.system_update_alt,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Update Available',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    'New version ${info.latestVersion} is out!',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DOWNLOAD',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideY(
                        begin: 1,
                        end: 0,
                        duration: 800.ms,
                        curve: Curves.easeOutBack);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, bool isDark,
      Color textColor, Color mutedTextColor, Color cardColor, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL COLLECTION',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: mutedTextColor)),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final gamesAsync =
                          await ref.read(allGamesProvider.future);
                      final List<Game> sortedGames = List<Game>.from(gamesAsync as Iterable);
                      sortedGames.sort((a, b) => (b.activeMarketValue ?? 0)
                          .compareTo(a.activeMarketValue ?? 0));
                      final top10 = sortedGames.take(10).toList();

                      if (context.mounted) {
                        final state =
                            ref.read<HomeState>(homeControllerProvider);
                        final currency = ref.read(currencyProvider);
                        final shareService = ShareService();
                        await shareService.shareSnapshot(
                          context,
                          CollectionSnapshotWidget(
                            top10Games: top10,
                            totalValuation: state.totalValuation,
                            totalGames: state.totalGames,
                            currency: currency,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: mutedTextColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final hidePricing = ref.watch(homeControllerProvider
                          .select<bool>((s) => s.hidePricing));
                      return IconButton(
                        onPressed: () => ref
                            .read(homeControllerProvider.notifier)
                            .togglePricingVisibility(),
                        icon: Icon(
                          hidePricing
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                          color: mutedTextColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Consumer(
            builder: (context, ref, _) {
              final hidePricing = ref.watch(
                  homeControllerProvider.select<bool>((s) => s.hidePricing));
              final totalValuation = ref.watch(homeControllerProvider
                  .select<double>((s) => s.totalValuation));
              final currency = ref.watch(currencyProvider);

              return Text(
                hidePricing ? '****' : currency.format(totalValuation),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text('Across platforms',
              style:
                  TextStyle(color: mutatedTextColor(textColor), fontSize: 16)),
          const SizedBox(height: 12),
          Consumer(builder: (context, ref, _) {
            final stats = ref.watch(homeControllerProvider);
            final delta = stats.weeklyDelta;
            final isGain = delta >= 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isGain ? AppTheme.gainGreen : AppTheme.lossRed)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isGain ? Icons.trending_up : Icons.trending_down,
                      color: isGain ? AppTheme.gainGreen : AppTheme.lossRed,
                      size: 14),
                  const SizedBox(width: 4),
                  Text(
                      '${isGain ? '+' : ''}${ref.watch(currencyProvider).format(delta)} this week',
                      style: TextStyle(
                          color: isGain ? AppTheme.gainGreen : AppTheme.lossRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(homeControllerProvider);
              return ValuationChart(
                history: state.valueHistory,
                hidePricing: state.hidePricing,
              );
            },
          ),
          const SizedBox(height: 40),

          // FEAT 2D: PORTFOLIO PERFORMANCE
          Consumer(builder: (context, ref, _) {
            final games = ref.watch(libraryStreamProvider).value ?? <Game>[];
            final withPurchasePrice =
                games.where((g) => g.purchasePrice != null).toList();
            final totalInvested =
                withPurchasePrice.fold(0.0, (s, g) => s + (g.purchasePrice ?? 0));
            final totalMarket = withPurchasePrice.fold(
                0.0, (s, g) => s + (g.activeMarketValue ?? 0));
            final totalGain = totalMarket - totalInvested;
            final isGain = totalGain >= 0;

            if (withPurchasePrice.isEmpty) return const SizedBox.shrink();

            final gainColor = isGain ? Colors.greenAccent : Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: gainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gainColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(isGain ? Icons.trending_up : Icons.trending_down,
                      color: gainColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PORTFOLIO PERFORMANCE',
                            style: TextStyle(
                                color: gainColor.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          '${isGain ? '+' : ''}${ref.watch(currencyProvider).format(totalGain)} on ${withPurchasePrice.length} tracked games',
                          style: TextStyle(
                              color: gainColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // FEAT 2E: RECENTLY ADDED
          Consumer(builder: (context, ref, _) {
            final games = ref.watch(libraryStreamProvider).value ?? <Game>[];
            if (games.isEmpty) return const SizedBox.shrink();
            final recent = games.take(5).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text('RECENTLY ADDED',
                    style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: mutedTextColor)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 135,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final g = recent[i];
                      return GestureDetector(
                        onTap: () => context.push('/game/${g.id}'),
                        child: SizedBox(
                          width: 90,
                          child: GameBox3D(coverUrl: g.coverUrl, title: g.title),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PLATFORMS',
                  style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: mutedTextColor)),
              TextButton(
                onPressed: () => context.push('/insights'),
                child: const Text('View All Insights',
                    style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCollectionListItem(context, ref,
                  title: 'PlayStation',
                  filter: 'ps_disc',
                  iconWidget: const FaIcon(FontAwesomeIcons.playstation,
                      color: Colors.blueAccent, size: 28),
                  iconBgColor: AppTheme.surface2,
                  cardColor: cardColor,
                  textColor: textColor)
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(context, ref,
                  title: 'PSN Digital',
                  filter: 'psn',
                  iconWidget: const FaIcon(FontAwesomeIcons.playstation,
                      color: Colors.cyanAccent, size: 28),
                  iconBgColor: AppTheme.surface2,
                  cardColor: cardColor,
                  textColor: textColor)
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(context, ref,
                  title: 'Steam',
                  filter: 'steam',
                  iconWidget: const FaIcon(FontAwesomeIcons.steam,
                      color: Colors.white, size: 28),
                  iconBgColor: AppTheme.surface2,
                  cardColor: cardColor,
                  textColor: textColor)
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(context, ref,
                  title: 'Epic Games',
                  filter: 'epic',
                  iconWidget:
                      const Icon(Icons.gamepad, color: Colors.white, size: 28),
                  iconBgColor: AppTheme.surface2,
                  cardColor: cardColor,
                  textColor: textColor)
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(context, ref,
                  title: 'Nintendo',
                  filter: 'nintendo',
                  iconWidget: const Icon(Icons.videogame_asset,
                      color: Colors.white, size: 28),
                  iconBgColor: AppTheme.surface2,
                  cardColor: cardColor,
                  textColor: textColor)
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Color mutatedTextColor(Color c) => c.withValues(alpha: 0.5);

  Widget _buildCollectionListItem(BuildContext context, WidgetRef ref,
      {required String title,
      required String filter,
      required Widget iconWidget,
      required Color iconBgColor,
      required Color cardColor,
      required Color textColor}) {
    final stats = ref.watch(homeControllerProvider.select<PlatformStat>((s) =>
        s.platformStats[filter.replaceAll(' ', '').toLowerCase()] ??
        s.platformStats[filter] ??
        const PlatformStat(0, 0)));
    final hidePricing =
        ref.watch(homeControllerProvider.select<bool>((s) => s.hidePricing));
    final currency = ref.watch(currencyProvider);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withValues(alpha: 0.05)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            hoverColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            onTap: () {
              context.push('/collections?platform=$filter');
            },
            highlightColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: iconWidget,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 4),
                        Text('${stats.count} games',
                            style: TextStyle(
                                color: mutatedTextColor(textColor),
                                fontSize: 13))
                      ],
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(hidePricing ? '****' : currency.format(stats.value),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right,
                        color: mutatedTextColor(textColor), size: 16),
                  ])
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(
      BuildContext context, WidgetRef ref, bool isDark, bool isDesktop) {
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 150,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(
                width: 250,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 60),
            Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            ...List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}
