import 'package:flutter/material.dart';
import '../core/cache_manager.dart';
import '../core/tokens.dart';
import '../models/game.dart';
import 'network_cover.dart';

/// Cover art with a decoded-size cap (cheap on memory) and a readable fallback.
class GameCover extends StatelessWidget {
  const GameCover({super.key, required this.game, this.cacheWidth = 300});
  final Game game;
  final int cacheWidth;

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
    return NetworkCover(
      url: url,
      cacheManager: gameCoverCacheManager,
      cacheWidth: cacheWidth,
      placeholder: ColoredBox(color: t.surface2),
      fallback: fallback,
    );
  }
}
