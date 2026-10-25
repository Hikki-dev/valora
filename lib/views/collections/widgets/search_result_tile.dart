import 'package:flutter/material.dart';
import '../../../core/tokens.dart';
import '../../../widgets/comic.dart';
import 'game_box_3d.dart';

/// One row in the add-game search results: a cover, the title and a chevron.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.title,
    required this.thumbUrl,
    required this.onTap,
  });

  final String title;
  final String? thumbUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return PressableBox(
      shadowOffset: 3,
      minHeight: 72,
      padding: const EdgeInsets.all(8),
      semanticLabel: 'Choose $title',
      onTap: onTap,
      child: Row(
        children: [
          // The cover fills the box it is given, so it needs a height of its own:
          // a list row has no height limit, and without one the row cannot lay out.
          SizedBox(
              width: 46,
              height: 66,
              child: GameBox3D(coverUrl: thumbUrl, title: title)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VText.body(15, t.text, weight: FontWeight.w900)),
          ),
          Icon(Icons.chevron_right, color: t.muted),
        ],
      ),
    );
  }
}
