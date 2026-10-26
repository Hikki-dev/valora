import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A picture from a web address. On the web the browser draws it itself (an
/// <img> element), so cover art from stores that do not send cross-origin
/// permission headers (Steam, GamesGate) still shows. Elsewhere it is cached
/// and decoded at a capped size.
class NetworkCover extends StatelessWidget {
  const NetworkCover({
    super.key,
    required this.url,
    required this.fallback,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheManager,
  });

  final String url;
  final Widget fallback;
  final Widget? placeholder;
  final BoxFit fit;
  final int? cacheWidth;
  final BaseCacheManager? cacheManager;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: placeholder == null
            ? null
            : (_, child, progress) => progress == null ? child : placeholder!,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: cacheManager,
      memCacheWidth: cacheWidth,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: placeholder == null ? null : (_, __) => placeholder!,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
