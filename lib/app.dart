import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/platform_utils.dart';

import 'core/theme.dart';
import 'core/tokens.dart';
import 'widgets/app_shell.dart';
import 'views/collections/add_game_modal.dart';
import 'views/home/home_view.dart';
import 'views/auth/login_view.dart';
import 'views/collections/collections_view.dart';
import 'views/collections/game_detail_view.dart';
import 'views/wishlists/wishlists_view.dart';
import 'views/home/insights_view.dart';
import 'views/onboarding/onboarding_overlay.dart';
import 'views/home/profile_view.dart';
import 'controllers/onboarding_controller.dart';
import 'controllers/auth_controller.dart';
import 'core/currency_provider.dart';

final wishlistDealCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;
  try {
    final res = await Supabase.instance.client
        .from('wishlists')
        .select('id, current_price, target_price')
        .eq('alerted', false);

    int count = 0;
    for (var item in res) {
      if (item['current_price'] != null && item['target_price'] != null) {
        if ((item['current_price'] as num) <= (item['target_price'] as num)) {
          count++;
        }
      }
    }
    return count;
  } catch (e) {
    return 0;
  }
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    // Trigger onboarding check on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).checkOnboarding();
    });
  }

  void _go(int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/collections');
      case 2:
        context.go('/wishlists');
      case 3:
        context.go('/profile');
    }
  }

  void _openAddGame() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddGameModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final double width = MediaQuery.sizeOf(context).width;
    final bool isMobile = width < 600;
    final bool isDesktop = width >= 1000;

    int currentIndex = 0;
    if (location.startsWith('/collections')) currentIndex = 1;
    if (location.startsWith('/wishlists')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    final t = VTokens.of(context);
    final onboardingState = ref.watch(onboardingControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dealCount = ref.watch(wishlistDealCountProvider).valueOrNull ?? 0;
    final isLkr = ref.watch(currencyProvider).currency == AppCurrency.lkr;

    Widget body = Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: widget.child,
          ),
        ),
        if (onboardingState.type != OnboardingType.none)
          OnboardingOverlay(
            isFull: onboardingState.type == OnboardingType.full,
            lastSeenCount: onboardingState.lastSeenCount,
          ),
      ],
    );

    if (!isMobile) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Row(
          children: [
            isDesktop
                ? VSidebar(
                    index: currentIndex,
                    onNav: _go,
                    onAddGame: _openAddGame,
                    onInsights: () => context.go('/insights'),
                    isDark: isDark,
                    onTheme: (dark) {
                      if (dark != isDark) {
                        ref.read(themeProvider.notifier).toggle();
                      }
                    },
                    isLkr: isLkr,
                    onCurrency: (lkr) {
                      if (lkr != isLkr) {
                        ref.read(currencyProvider.notifier).toggleCurrency();
                      }
                    },
                    onSignOut: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    dealCount: dealCount,
                  )
                : VRail(
                    index: currentIndex,
                    onNav: _go,
                    onAddGame: _openAddGame,
                    isDark: isDark,
                    onTheme: () => ref.read(themeProvider.notifier).toggle(),
                    onSignOut: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    dealCount: dealCount,
                  ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: body,
      bottomNavigationBar: onboardingState.type == OnboardingType.none
          ? VBottomNav(index: currentIndex, onTap: _go, dealCount: dealCount)
          : null,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.uri.toString() == '/login';

      if (session == null && !isLoggingIn) return '/login';
      if (session != null && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginView()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeView()),
          ),
          GoRoute(
            path: '/collections',
            pageBuilder: (context, state) {
              final platform = state.uri.queryParameters['platform'];
              return NoTransitionPage(
                  child: CollectionsView(platformFilter: platform));
            },
          ),
          GoRoute(
            path: '/wishlists',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WishlistsView()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileView()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InsightsView()),
          ),
          GoRoute(
            path: '/game/:id',
            pageBuilder: (context, state) {
              final gameId = state.pathParameters['id']!;
              return CustomTransitionPage(
                child: GameDetailView(gameId: gameId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                        parent: animation, curve: Curves.easeOut),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              );
            },
          ),
        ],
      ),
    ],
  );
});

bool _firstFrameSignalled = false;

class ValoraApp extends ConsumerWidget {
  const ValoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Onboarding check: Trigger on auth changes or once at startup
    ref.listen(authControllerProvider, (prev, next) {
      if (next.value != null && prev?.value == null) {
        ref.read(onboardingControllerProvider.notifier).checkOnboarding();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authControllerProvider).value != null) {
        ref.read(onboardingControllerProvider.notifier).checkOnboarding();
      }

      // Signal to the web container that the first frame is rendered (once).
      if (!_firstFrameSignalled) {
        _firstFrameSignalled = true;
        PlatformUtils.signalFirstFrame();
      }
    });

    return MaterialApp.router(
      title: 'Valora',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
