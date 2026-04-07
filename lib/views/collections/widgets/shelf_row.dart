import 'package:flutter/material.dart';

class ShelfRow extends StatelessWidget {
  final List<Widget> children;
  
  const ShelfRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24), // Spacing between shelves
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The Shelf Base (Glassmorphism & Neon Edge)
          Positioned(
            bottom: -15, // Offset to make games sit 'on' it
            left: 0,
            right: 0,
            child: Container(
              height: 25,
              decoration: BoxDecoration(
                // The translucent glass edge
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.cyanAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
            ),
          ),
          
          // Row of Games
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // shelf margin
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: children.map((child) => 
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: child,
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
