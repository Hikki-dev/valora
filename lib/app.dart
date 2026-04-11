import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/platform_utils.dart';

import 'core/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    int currentIndex = 0;
    if (location.startsWith('/collections')) currentIndex = 1;
    if (location.startsWith('/wishlists')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    final onboardingState = ref.watch(onboardingControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    Widget body = Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context, ref, currentIndex, isDark),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: onboardingState.type == OnboardingType.none
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index == 0) context.go('/');
                if (index == 1) context.go('/collections');
                if (index == 2) context.go('/wishlists');
                if (index == 3) context.go('/profile');
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: textColor.withValues(alpha: 0.5),
              items: [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: 'Home'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.library_books), label: 'Library'),
                BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: ref.watch(wishlistDealCountProvider).valueOrNull != null && ref.watch(wishlistDealCountProvider).value! > 0,
                      label: Text('${ref.watch(wishlistDealCountProvider).valueOrNull ?? 0}'),
                      child: const Icon(Icons.favorite),
                    ),
                    label: 'Wishlist'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : null,
    );
  }

  Widget _buildSidebar(
      BuildContext context, WidgetRef ref, int currentIndex, bool isDark) {
    final themeToggleIcon = isDark ? Icons.light_mode : Icons.dark_mode;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14141A) : Colors.white,
        border:
            Border(right: BorderSide(color: textColor.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_graph,
                        color: Theme.of(context).primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Valora',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildSidebarItem(context, Icons.home_rounded, 'Home',
              currentIndex == 0, () => context.go('/')),
          _buildSidebarItem(context, Icons.library_books, 'Library',
              currentIndex == 1, () => context.go('/collections')),
          _buildSidebarItem(context, Icons.favorite, 'Wishlist',
              currentIndex == 2, () => context.go('/wishlists')),
          _buildSidebarItem(context, Icons.person, 'Profile', currentIndex == 3,
              () => context.go('/profile')),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSidebarAction(context, themeToggleIcon, 'Toggle Theme',
                    () => ref.read(themeProvider.notifier).toggle()),
                _buildSidebarAction(
                    context,
                    Icons.currency_exchange,
                    'Currency',
                    () => ref.read(currencyProvider.notifier).toggleCurrency()),
                const Divider(height: 32),
                _buildSidebarAction(context, Icons.logout, 'Sign Out',
                    () => ref.read(authControllerProvider.notifier).signOut(),
                    isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String label,
      bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? activeColor : textColor.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? textColor : textColor.withValues(alpha: 0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final color =
        isDestructive ? Colors.redAccent : textColor.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
                    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
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

      // Signal to the web container that the first frame is rendered
      PlatformUtils.signalFirstFrame();
    });

    return MaterialApp.router(
      title: 'Valora',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
