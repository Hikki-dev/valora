import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'views/home/home_view.dart';
import 'views/auth/login_view.dart';
import 'views/collections/collections_view.dart';
import 'views/collections/game_detail_view.dart';
import 'views/wishlists/wishlists_view.dart';
import 'views/onboarding/onboarding_overlay.dart';
import 'controllers/onboarding_controller.dart';
import 'controllers/auth_controller.dart';


class RouterNotifier extends ChangeNotifier {
  RouterNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}



class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/collections')) currentIndex = 1;
    if (location.startsWith('/wishlists')) currentIndex = 2;

    final onboardingState = ref.watch(onboardingControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (onboardingState != OnboardingState.none)
            OnboardingOverlay(isFull: onboardingState == OnboardingState.full),
        ],
      ),
      bottomNavigationBar: onboardingState == OnboardingState.none 
          ? BottomNavigationBar(

        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/collections');
          if (index == 2) context.go('/wishlists');
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
        ],
        )
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
        builder: (context, state) => const LoginView(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: '/collections',
            builder: (context, state) {
              final platform = state.uri.queryParameters['platform'];
              return CollectionsView(platformFilter: platform);
            },
          ),
          GoRoute(
            path: '/wishlists',
            builder: (context, state) => const WishlistsView(),
          ),
          GoRoute(
            path: '/game/:id',
            builder: (context, state) {
              final gameId = state.pathParameters['id']!;
              return GameDetailView(gameId: gameId);
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

    // Initial onboarding check when auth state changes
    ref.listen(authControllerProvider, (previous, next) {
      if (next.value != null) {
        ref.read(onboardingControllerProvider.notifier).checkOnboarding();
      }
    });

    // Check on startup if already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user != null) {
        ref.read(onboardingControllerProvider.notifier).checkOnboarding();
      }
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
