import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/content_providers.dart';
import '../features/album/album_screen.dart';
import '../features/album/binder_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/boosters/opening_screen.dart';
import '../features/cards/card_detail_screen.dart';
import '../features/combat/combat_screen.dart';
import '../features/credits/credits_screen.dart';
import '../features/entry/entry_screen.dart';
import '../features/fighters/fighter_detail_screen.dart';
import '../features/fighters/fighters_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/showcase/showcase_screen.dart';
import '../widgets/arena_background.dart';

/// Rafraîchit go_router à chaque changement de session.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(supabaseProvider).auth;
  final listenable = _AuthListenable(auth.onAuthStateChange);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    // Écran d'entrée à chaque lancement de l'app
    initialLocation: '/entree',
    refreshListenable: listenable,
    redirect: (context, state) {
      if (state.matchedLocation == '/entree') return null;
      final loggedIn = auth.currentSession != null;
      final onAuthPage = state.matchedLocation == '/connexion' || state.matchedLocation == '/inscription';
      if (!loggedIn && !onAuthPage) return '/connexion';
      if (loggedIn && onAuthPage) return '/accueil';
      return null;
    },
    routes: [
      GoRoute(
        path: '/entree',
        pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const EntryScreen()),
      ),
      GoRoute(path: '/connexion', builder: (_, _) => const ArenaBackground(intensity: 0.7, child: LoginScreen())),
      GoRoute(path: '/inscription', builder: (_, _) => const ArenaBackground(intensity: 0.7, child: SignupScreen())),
      GoRoute(path: '/reglages', builder: (_, _) => const ArenaBackground(intensity: 0.12, child: SettingsScreen())),
      GoRoute(path: '/credits', builder: (_, _) => const ArenaBackground(intensity: 0.12, child: CreditsScreen())),
      GoRoute(path: '/vitrine', builder: (_, _) => const ArenaBackground(intensity: 0.12, child: ShowcaseScreen())),
      GoRoute(
        path: '/booster/:typeId',
        builder: (_, s) => BoosterOpeningScreen(
          typeId: Uri.decodeComponent(s.pathParameters['typeId']!),
          payment: s.uri.queryParameters['paiement'] ?? 'gratuit',
        ),
      ),
      GoRoute(
        path: '/carte/:cardId',
        builder: (_, s) => CardDetailScreen(
          cardId: Uri.decodeComponent(s.pathParameters['cardId']!),
          variantId: s.uri.queryParameters['variant'],
          ownedId: s.uri.queryParameters['owned'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/accueil', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/album',
              builder: (_, _) => const AlbumScreen(),
              routes: [
                GoRoute(
                  path: ':editionId',
                  // Page empilée dans l'onglet : son propre fond (opaque) pendant la transition
                  builder: (_, s) =>
                      ArenaBackground(intensity: 0.12, child: BinderScreen(editionId: s.pathParameters['editionId']!)),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/combattants',
              builder: (_, _) => const FightersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) =>
                      ArenaBackground(intensity: 0.12, child: FighterDetailScreen(fighterId: s.pathParameters['id']!)),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/combat', builder: (_, _) => const CombatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profil', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
