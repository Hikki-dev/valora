import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';


import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../core/currency_provider.dart';
import 'insights_view.dart';
import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../services/share_service.dart';
import 'widgets/collection_snapshot.dart';



class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeToggleIcon = isDark ? Icons.light_mode : Icons.dark_mode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5);
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isDesktop ? null : AppBar(
        title: Text('Valora', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(themeToggleIcon, color: textColor.withValues(alpha: 0.7)),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.currency_exchange, color: textColor.withValues(alpha: 0.7)),
            onPressed: () => ref.read(currencyProvider.notifier).toggleCurrency(),
            tooltip: 'Toggle Currency',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: textColor.withValues(alpha: 0.7)),
            onPressed: () {
               ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
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
        child: SafeArea(
          child: state.isLoading 
              ? _buildSkeleton(context, ref, isDark, isDesktop)
              : _buildDashboard(context, ref, state, isDark, textColor, mutedTextColor, cardColor, isDesktop),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, HomeState state, bool isDark, Color textColor, Color mutedTextColor, Color cardColor, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL COLLECTION', 
                style: TextStyle(
                  fontSize: 12, 
                  letterSpacing: 2, 
                  fontWeight: FontWeight.w700, 
                  color: mutedTextColor
                )
              ),
              Row(
                children: [
                   IconButton(
                    onPressed: () async {
                      final gamesAsync = await ref.read(allGamesProvider.future);
                      final sortedGames = List<Game>.from(gamesAsync);
                      sortedGames.sort((a, b) => (b.activeMarketValue ?? 0).compareTo(a.activeMarketValue ?? 0));
                      final top10 = sortedGames.take(10).toList();

                      if (context.mounted) {
                        final state = ref.read(homeControllerProvider);
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
                  IconButton(
                    onPressed: () => ref.read(homeControllerProvider.notifier).togglePricingVisibility(),
                    icon: Icon(
                      state.hidePricing ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 16,
                      color: mutedTextColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

            ],
          ),
          const SizedBox(height: 4),

          Text(
            state.hidePricing ? '****' : ref.watch(currencyProvider).format(state.totalValuation),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Across platforms', 
            style: TextStyle(color: mutatedTextColor(textColor), fontSize: 16)
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
               color: Colors.green.withValues(alpha: 0.15),
               borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.star, color: Colors.green, size: 14),
                 const SizedBox(width: 4),
                 const Text('+\$42 this week', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
               ],
            ),
          ),
          const SizedBox(height: 40),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COLLECTIONS', 
                style: TextStyle(
                  fontSize: 13, 
                  letterSpacing: 2, 
                  fontWeight: FontWeight.w700, 
                  color: mutedTextColor
                )
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsView())),
                child: const Text('View All Insights', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildCollectionListItem(
             context, 
             ref,
             state,
             title: 'PlayStation', 
             filter: 'playstation', 
             iconWidget: const FaIcon(FontAwesomeIcons.playstation, color: Colors.blueAccent, size: 28),
             iconBgColor: const Color(0xFF0D47A1), 
             cardColor: cardColor, 
             textColor: textColor
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(
             context, 
             ref,
             state,
             title: 'Steam', 
             filter: 'steam', 
             iconWidget: const FaIcon(FontAwesomeIcons.steam, color: Colors.white, size: 28),
             iconBgColor: const Color(0xFF171A21), 
             cardColor: cardColor, 
             textColor: textColor
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(
             context, 
             ref,
             state,
             title: 'Epic Games', 
             filter: 'epic', 
             iconWidget: const Icon(Icons.gamepad, color: Colors.white, size: 28),


             iconBgColor: const Color(0xFF000000), 
             cardColor: cardColor, 
             textColor: textColor
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
          _buildCollectionListItem(
             context, 
             ref,
             state,
             title: 'Nintendo', 
             filter: 'nintendo', 
             iconWidget: const Icon(Icons.videogame_asset, color: Colors.white, size: 28),


             iconBgColor: const Color(0xFFE60012), 
             cardColor: cardColor, 
             textColor: textColor
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Color mutatedTextColor(Color c) => c.withValues(alpha: 0.5);

  Widget _buildCollectionListItem(
    BuildContext context, 
    WidgetRef ref,
    HomeState state,
    {
      required String title, 
      required String filter, 
      required Widget iconWidget, 
      required Color iconBgColor, 
      required Color cardColor, 
      required Color textColor
    }
  ) {
    final stats = state.platformStats[filter.replaceAll(' ', '').toLowerCase()] ?? state.platformStats[filter] ?? const PlatformStat(0, 0);
    final currency = ref.watch(currencyProvider);

    return Container(
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
          highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                       Text(
                         title, 
                         style: TextStyle(
                           fontSize: 18, 
                           fontWeight: FontWeight.bold, 
                           color: textColor
                         )
                       ),
                       const SizedBox(height: 4),
                       Text(
                         '${stats.count} games',
                         style: TextStyle(color: mutatedTextColor(textColor), fontSize: 13)
                       )
                     ],
                   ),
                 ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text(
                        state.hidePricing ? '****' : currency.format(stats.value),
                        style: TextStyle(
                           fontSize: 18, 
                           fontWeight: FontWeight.bold, 
                           color: textColor
                        )
                     ),
                     const SizedBox(height: 4),
                     Icon(Icons.chevron_right, color: mutatedTextColor(textColor), size: 16),
                   ]
                 )
               ],
             ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, WidgetRef ref, bool isDark, bool isDesktop) {
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    final highlightColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(width: 250, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 60),
            Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 80,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
