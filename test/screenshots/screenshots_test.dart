// Makes the pictures used in README.md. It shows the real screens with
// made-up demo games, so it needs no account and no network.
//
//   flutter test test/screenshots --update-goldens   (writes docs/images/*.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valora/app.dart';
import 'package:valora/controllers/home_controller.dart';
import 'package:valora/core/theme.dart';
import 'package:valora/models/game.dart';
import 'package:valora/models/wishlist_item.dart';
import 'package:valora/repositories/game_repository.dart';
import 'package:valora/models/price_data.dart';
import 'package:valora/views/collections/collections_view.dart';
import 'package:valora/views/collections/game_detail_view.dart';
import 'package:valora/views/collections/add_game_modal.dart';
import 'package:valora/views/home/profile_view.dart';
import 'package:valora/views/home/home_view.dart';
import 'package:valora/views/home/insights_view.dart';
import 'package:valora/views/wishlists/wishlists_view.dart';

Game _g(String id, String title, AppPlatform p, double? value,
        {double? paid, GameCondition c = GameCondition.cib}) =>
    Game(
      id: id,
      collectionId: 'c',
      userId: 'u',
      title: title,
      platform: p,
      condition: c,
      format: p.isPhysical ? 'Physical' : 'Digital',
      purchasePrice: paid,
      currentValue: value,
      estimatedValue: value,
      fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

final _games = [
  _g('1', 'Persona 5 Royal', AppPlatform.ps4Physical, 62.4, paid: 40),
  _g('2', 'Bloodborne', AppPlatform.ps4Physical, 48.0, paid: 55),
  _g('3', 'God of War Ragnarok', AppPlatform.ps5Physical, 34.5, paid: 30),
  _g('4', 'Elden Ring', AppPlatform.ps5Digital, 39.99, paid: 59.99),
  _g('5', 'Hades', AppPlatform.steam, 24.99, paid: 12),
  _g('6', 'Hollow Knight', AppPlatform.steam, 14.99, paid: 9),
  _g('7', 'Celeste', AppPlatform.steam, 19.99, paid: 5),
  _g('8', 'Disco Elysium', AppPlatform.steam, 39.99, paid: 20),
  _g('9', 'The Witcher 3', AppPlatform.epic, 29.99, paid: 0),
  _g('10', 'Zelda: Tears of the Kingdom', AppPlatform.nintendo, 54.0, paid: 60),
  _g('11', 'Metroid Dread', AppPlatform.nintendo, 44.0, paid: 35),
  _g('12', 'Stardew Valley', AppPlatform.steam, 14.99),
];

final _wishlist = [
  WishlistItem(
      id: 'w1',
      userId: 'u',
      title: 'Silksong',
      platform: AppPlatform.steam,
      targetPrice: 15,
      currentPrice: 19.99),
  WishlistItem(
      id: 'w2',
      userId: 'u',
      title: 'Astro Bot',
      platform: AppPlatform.ps5Physical,
      targetPrice: 40,
      currentPrice: 38.5),
  WishlistItem(
      id: 'w3',
      userId: 'u',
      title: 'Metaphor: ReFantazio',
      platform: AppPlatform.ps5Physical,
      targetPrice: 35,
      currentPrice: 41),
  WishlistItem(
      id: 'w4',
      userId: 'u',
      title: 'Balatro',
      platform: AppPlatform.steam,
      targetPrice: 10,
      currentPrice: 9.99),
];

class _DemoHome extends HomeController {
  @override
  HomeState build() {
    final s = super.build();
    final total = s.totalValuation;
    return s.copyWith(valueHistory: [
      for (var i = 0; i < 30; i++)
        ValueSnapshot(DateTime.now().subtract(Duration(days: 29 - i)),
            total * (0.82 + 0.18 * i / 29 + (i % 4 == 0 ? 0.012 : 0))),
    ]);
  }
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(File(f).readAsBytes().then((b) => ByteData.sublistView(b)));
    }
    await l.load();
  }

  await load('DelaGothicOne', ['assets/fonts/DelaGothicOne-Regular.ttf']);
  await load('DotGothic16', ['assets/fonts/DotGothic16-Regular.ttf']);
  await load('ZenKakuGothicNew', [
    'assets/fonts/ZenKakuGothicNew-Regular.ttf',
    'assets/fonts/ZenKakuGothicNew-Bold.ttf',
    'assets/fonts/ZenKakuGothicNew-Black.ttf',
  ]);
  final sdk = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final mat =
      '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(mat).existsSync()) await load('MaterialIcons', [mat]);
  final pc = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final fa = '$pc/hosted/pub.dev/font_awesome_flutter-10.8.0/lib/fonts';
  if (Directory(fa).existsSync()) {
    await load('packages/font_awesome_flutter/FontAwesomeSolid',
        ['$fa/fa-solid-900.ttf']);
    await load('packages/font_awesome_flutter/FontAwesomeRegular',
        ['$fa/fa-regular-400.ttf']);
    await load('packages/font_awesome_flutter/FontAwesomeBrands',
        ['$fa/fa-brands-400.ttf']);
  }
}

Future<void> _shot(WidgetTester tester, String path, String name, Size size,
    {bool dark = false,
    List<Override> extra = const [],
    Future<void> Function(WidgetTester)? act}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  final router = GoRouter(initialLocation: path, routes: [
    ShellRoute(
      builder: (c, s, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeView()),
        GoRoute(
            path: '/collections', builder: (c, s) => const CollectionsView()),
        GoRoute(path: '/wishlists', builder: (c, s) => const WishlistsView()),
        GoRoute(path: '/insights', builder: (c, s) => const InsightsView()),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileView()),
        GoRoute(
            path: '/game/:id',
            builder: (c, s) => GameDetailView(gameId: s.pathParameters['id']!)),
      ],
    ),
  ]);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      libraryStreamProvider.overrideWith((ref) => Stream.value(_games)),
      allGamesProvider.overrideWith((ref) async => _games),
      wishlistProvider.overrideWith((ref) async => _wishlist),
      wishlistDealCountProvider.overrideWith((ref) async => 2),
      homeControllerProvider.overrideWith(_DemoHome.new),
      ...extra,
    ],
    child: RepaintBoundary(
      key: key,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    ),
  ));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  if (act != null) {
    await act(tester);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    File('docs/images/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'http://localhost:1', anonKey: 'demo');
    await _loadFonts();
  });

  const phone = Size(390, 844);
  const desktop = Size(1440, 900);
  final pages = {
    'home': '/',
    'library': '/collections',
    'wishlist': '/wishlists',
    'insights': '/insights',
  };
  for (final e in pages.entries) {
    testWidgets(
        '${e.key} phone', (t) => _shot(t, e.value, '${e.key}-mobile', phone));
    testWidgets('${e.key} desktop',
        (t) => _shot(t, e.value, '${e.key}-desktop', desktop));
  }

  final game = _games.first;
  final detail = [
    gameDetailProvider.overrideWith((ref, id) async => game),
    gamePricesProvider.overrideWith((ref, id) async => PriceData(
        loosePrice: 31.0,
        cibPrice: 62.4,
        newPrice: 118.0,
        source: 'PriceCharting')),
    gameHistoryProvider.overrideWith((ref, id) async => [
          for (var i = 0; i < 12; i++)
            {
              'fetched_at': DateTime(2026, 5, 1)
                  .add(Duration(days: i * 16))
                  .toIso8601String(),
              'price_complete': 48.0 + i * 1.3 + (i % 3) * 0.8,
              'price_loose': 25.0 + i * 0.5,
              'price_new': 90.0 + i * 2.2,
            }
        ]),
  ];
  for (final d in {'mobile': phone, 'desktop': desktop}.entries) {
    testWidgets('game ${d.key}',
        (t) => _shot(t, '/game/1', 'game-${d.key}', d.value, extra: detail));
    testWidgets('settings ${d.key}',
        (t) => _shot(t, '/profile', 'settings-${d.key}', d.value));
    testWidgets('home dark ${d.key}',
        (t) => _shot(t, '/', 'home-dark-${d.key}', d.value, dark: true));
    testWidgets(
        'add game ${d.key}',
        (t) => _shot(t, '/', 'add-game-${d.key}', d.value, act: (t) async {
              await t.tap(find.text('Add game').first);
              await t.pump();
            }));
  }
  testWidgets('library list desktop', (t) async {
    await _shot(t, '/collections', 'library-list-desktop', desktop,
        act: (t) async {
      await t.tap(find.text('List').first);
      await t.pump();
    });
  });
}
