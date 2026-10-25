// The add-game search results are drawn in a scrolling list, which gives each
// row no height limit. A row whose cover has a width but no height throws a
// layout error there, and the release web build shows that as a blank area.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valora/core/theme.dart';
import 'package:valora/views/collections/widgets/search_result_tile.dart';

void main() {
  testWidgets('search results lay out inside a list without a layout error',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => SearchResultTile(
                title: 'Persona 5 Royal $i',
                thumbUrl: null,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Persona 5 Royal 0'), findsWidgets);
    expect(find.byType(SearchResultTile), findsNWidgets(3));
  });
}
