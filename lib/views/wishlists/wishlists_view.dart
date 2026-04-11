import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../repositories/wishlist_repository.dart';
import '../../models/wishlist_item.dart';
import '../collections/add_game_modal.dart';
import '../../core/currency_provider.dart';

final wishlistProvider =
    FutureProvider.autoDispose<List<WishlistItem>>((ref) async {
  return ref.read(wishlistRepositoryProvider).getWishlist();
});

class WishlistsView extends ConsumerWidget {
  const WishlistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text('WISHLIST',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black87)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48.0 : 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  const SizedBox(height: 32),
                  Text(
                    'WISHLIST',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Expanded(
                  child: wishlistAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 64,
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                "Your wishlist is empty.\nLet's track some deals!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withValues(alpha: 0.5),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }

                      if (isDesktop) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 0,
                            mainAxisExtent: 160,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildWishlistItem(
                                context, ref, item, index);
                          },
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildWishlistItem(context, ref, item, index);
                        },
                      );
                    },
                    loading: () => _buildSkeleton(context, isDark, isDesktop),
                    error: (err, st) => Center(
                        child: Text('Error: $err',
                            style: const TextStyle(color: Colors.red))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(context),
    );
  }

  Widget _buildWishlistItem(
      BuildContext context, WidgetRef ref, WishlistItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final currency = ref.watch(currencyProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Future: Show wishlist details or allow editing target price
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'wishlist_cover_${item.id}',
                  child: Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.coverUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                          )
                        : const Center(
                            child: Icon(Icons.videogame_asset,
                                color: Colors.white24)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: -0.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.platform.label.toUpperCase(),
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TARGET',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                              Text(
                                item.targetPrice != null
                                    ? currency.format(item.targetPrice!)
                                    : 'ANY DEAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.currentPrice != null &&
                                  item.targetPrice != null &&
                                  item.currentPrice! <= item.targetPrice!)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('🔥 DEAL REACHED',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900)),
                                ),
                              Text('CURRENT',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                              Text(
                                item.currentPrice != null
                                    ? currency.format(item.currentPrice!)
                                    : 'TRACKING...',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: item.currentPrice != null &&
                                            item.targetPrice != null &&
                                            item.currentPrice! <=
                                                item.targetPrice!
                                        ? Colors.greenAccent
                                        : (item.currentPrice == null
                                            ? Colors.cyanAccent
                                            : Colors.orangeAccent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (item.currentPrice == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Awaiting digital price point...',
                              style: TextStyle(
                                  color:
                                      Colors.cyanAccent.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_task,
                      color: Theme.of(context).primaryColor, size: 20),
                  tooltip: 'Move to Collection',
                  onPressed: () async {
                    final added = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddGameModal(prefillItem: item),
                    );
                    if (added == true) {
                      await ref
                          .read(wishlistRepositoryProvider)
                          .deleteWishlistItem(item.id);
                      ref.invalidate(wishlistProvider);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    await ref
                        .read(wishlistRepositoryProvider)
                        .deleteWishlistItem(item.id);
                    ref.invalidate(wishlistProvider);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: 0.1, end: 0);
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
            builder: (context) => const AddGameModal(isWishlistMode: true),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark, bool isDesktop) {
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: isDesktop
          ? GridView.builder(
              padding: const EdgeInsets.all(0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisExtent: 160,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24))),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  height: 160,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24))),
            ),
    );
  }
}
