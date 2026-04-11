import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class GameBox3D extends StatefulWidget {
  final String? coverUrl;
  final String title;
  final String? purchasePriceText;
  final String? profitMarginText;
  final Color? profitMarginColor;
  final VoidCallback? onTap;

  const GameBox3D({
    super.key,
    required this.coverUrl,
    required this.title,
    this.purchasePriceText,
    this.profitMarginText,
    this.profitMarginColor,
    this.onTap,
  });

  @override
  State<GameBox3D> createState() => _GameBox3DState();
}

class _GameBox3DState extends State<GameBox3D> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_isHovered ? 0.05 : 0)
            ..rotateY(_isHovered ? -0.05 : 0)
            ..setTranslationRaw(0.0, _isHovered ? -8.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                )
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: widget.coverUrl != null && widget.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, err) => _buildFallback(),
                        placeholder: (context, url) =>
                            _buildFallback(loading: true),
                      )
                    : _buildFallback(),
              ),

              // 3D Inner Lighting & Shadow Effect
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2), // Top-left glare
                      Colors.transparent,
                      Colors.black
                          .withValues(alpha: 0.4), // Bottom-right shadow
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),

              // Left spine effect
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // Embedded Pricing Overlays
              if (widget.purchasePriceText != null ||
                  widget.profitMarginText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.0)
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.purchasePriceText != null)
                          Text(
                            widget.purchasePriceText!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          )
                        else
                          const SizedBox(), // Spacer

                        if (widget.profitMarginText != null)
                          Text(
                            widget.profitMarginText!,
                            style: TextStyle(
                                color: widget.profitMarginColor ?? Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback({bool loading = false}) {
    return Container(
      color: const Color(0xFF1E1E2C),
      child: Center(
        child: loading
            ? Shimmer.fromColors(
                baseColor: Colors.white.withValues(alpha: 0.05),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Container(color: Colors.white),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gamepad,
                          color: Colors.white54, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
