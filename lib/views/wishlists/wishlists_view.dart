import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/currency_provider.dart';
import '../../core/tokens.dart';
import '../../models/wishlist_item.dart';
import '../../repositories/wishlist_repository.dart';
import '../../widgets/comic.dart';
import '../collections/add_game_modal.dart';

final wishlistProvider =
    FutureProvider.autoDispose<List<WishlistItem>>((ref) async {
  return ref.read(wishlistRepositoryProvider).getWishlist();
});

class WishlistsView extends ConsumerStatefulWidget {
  const WishlistsView({super.key});

  @override
  ConsumerState<WishlistsView> createState() => _WishlistsViewState();
}

class _WishlistsViewState extends ConsumerState<WishlistsView> {
  /// Items hidden while their UNDO window is open.
  final Set<String> _hidden = {};

  Future<void> _add() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddGameModal(isWishlistMode: true),
      ).then((_) => ref.invalidate(wishlistProvider));

  void _remove(WishlistItem item) {
    final t = VTokens.of(context);
    final repo = ref.read(wishlistRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _hidden.add(item.id));
    messenger
        .showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: t.text,
          shape: Border.all(color: t.line, width: 2),
          duration: const Duration(seconds: 5),
          content: Text('${item.title} removed', style: VText.body(14, t.bg)),
          action: SnackBarAction(
              label: 'UNDO', textColor: t.money, onPressed: () {}),
        ))
        .closed
        .then((reason) async {
      if (reason == SnackBarClosedReason.action) {
        if (mounted) setState(() => _hidden.remove(item.id));
        return;
      }
      try {
        await repo.deleteWishlistItem(item.id);
      } catch (_) {
        // keep it visible again if the delete failed
      }
      if (mounted) {
        ref.invalidate(wishlistProvider);
        setState(() => _hidden.remove(item.id));
      }
    });
  }

  Future<void> _moveToLibrary(WishlistItem item) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGameModal(prefillItem: item),
    );
    if (added == true) {
      await ref.read(wishlistRepositoryProvider).deleteWishlistItem(item.id);
      ref.invalidate(wishlistProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final async = ref.watch(wishlistProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final pad = isDesktop ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(pad, isDesktop ? 32 : 16, pad, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WANT LIST', style: VText.label(12, t.muted)),
                            const SizedBox(height: 4),
                            Text('Wishlist',
                                style:
                                    VText.display(isDesktop ? 36 : 28, t.text)),
                            const SizedBox(height: 4),
                            Text(
                                'Games you’re watching. We’ll flag the ones at your target price.',
                                style: VText.body(13, t.muted,
                                    weight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PressableBox(
                        onTap: _add,
                        color: t.money,
                        semanticLabel: 'Add to wishlist',
                        shadowOffset: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add, size: 20, color: t.onMoney),
                          if (isDesktop) ...[
                            const SizedBox(width: 6),
                            Text('Add game',
                                style: VText.body(14, t.onMoney,
                                    weight: FontWeight.w900)),
                          ],
                        ]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: async.when(
                      loading: () => _Skeleton(isDesktop: isDesktop, pad: pad),
                      error: (e, _) => _Empty(
                        title: 'Couldn’t load your wishlist',
                        body: 'Check your connection and try again.',
                        action: 'Retry',
                        onAction: () => ref.invalidate(wishlistProvider),
                      ),
                      data: (all) {
                        final items =
                            all.where((i) => !_hidden.contains(i.id)).toList();
                        if (items.isEmpty) {
                          return _Empty(
                            title: 'Nothing on your wishlist yet',
                            body:
                                'Add a game you want and set a target price. We’ll show it when the market price drops to it.',
                            action: 'Add a game',
                            onAction: _add,
                          );
                        }
                        Widget cardBuilder(BuildContext c, int i) => _Card(
                              item: items[i],
                              index: i,
                              onMove: () => _moveToLibrary(items[i]),
                              onRemove: () => _remove(items[i]),
                            );
                        if (isDesktop) {
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 560,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              mainAxisExtent: 170,
                            ),
                            itemCount: items.length,
                            itemBuilder: cardBuilder,
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: cardBuilder,
                        );
                      },
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
}

class _Card extends ConsumerWidget {
  const _Card(
      {required this.item,
      required this.index,
      required this.onMove,
      required this.onRemove});
  final WishlistItem item;
  final int index;
  final VoidCallback onMove, onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final cur = item.currentPrice;
    final target = item.targetPrice;
    final reached = cur != null && target != null && cur <= target;

    Widget card = HardBox(
      shadowOffset: 4,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 104,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 104,
              decoration: BoxDecoration(
                  color: t.surface2,
                  border: Border.all(color: t.line, width: 2)),
              child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.coverUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 240,
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.videogame_asset, color: t.muted),
                    )
                  : Icon(Icons.videogame_asset, color: t.muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VText.body(16, t.text, weight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: t.surface2,
                          border: Border.all(color: t.line, width: 2)),
                      child: Text(item.platform.label,
                          style: VText.label(11, t.text, spacing: 1)),
                    ),
                    if (reached)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: t.gainBg,
                            border: Border.all(color: kInk, width: 2)),
                        child: Text('TARGET HIT',
                            style: VText.label(11, t.gainInk, spacing: 1)),
                      ),
                  ]),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Money(
                          label: 'TARGET',
                          value: target == null
                              ? 'Any price'
                              : currency.format(target),
                          color: t.text),
                      const SizedBox(width: 20),
                      _Money(
                          label: 'NOW',
                          value:
                              cur == null ? 'Checking…' : currency.format(cur),
                          color: reached ? t.gainInk : t.moneyText,
                          big: true),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _Act(
                    icon: Icons.add_task,
                    label: 'Move to library',
                    color: t.text,
                    onTap: onMove),
                _Act(
                    icon: Icons.delete_outline,
                    label: 'Remove from wishlist',
                    color: t.danger,
                    onTap: onRemove),
              ],
            ),
          ],
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context) || index > 5) return card;
    return card
        .animate()
        .fadeIn(duration: 260.ms, delay: (index * 50).ms)
        .slideY(begin: 0.04, end: 0, duration: 260.ms, delay: (index * 50).ms);
  }
}

class _Money extends StatelessWidget {
  const _Money(
      {required this.label,
      required this.value,
      required this.color,
      this.big = false});
  final String label, value;
  final Color color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Flexible(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VText.label(11, t.muted, spacing: 1)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: VText.display(big ? 18 : 14, color)),
        ),
      ],
    ));
  }
}

class _Act extends StatelessWidget {
  const _Act(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, size: 22, color: color),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarburstBadge(
                text: 'WANT!',
                size: 96,
                fill: t.money,
                textColor: kInk,
                textSize: 16,
              ),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: VText.display(20, t.text)),
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
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.isDesktop, required this.pad});
  final bool isDesktop;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    Widget box() => Container(color: Colors.white);
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.soft,
      child: isDesktop
          ? GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 560,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: 170),
              itemCount: 4,
              itemBuilder: (_, __) => box())
          : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, __) => SizedBox(height: 130, child: box())),
    );
  }
}
