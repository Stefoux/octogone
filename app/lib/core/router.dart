import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/content_providers.dart';
import '../features/album/album_screen.dart';
import '../features/album/binder_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/cards/card_detail_screen.dart';
import '../features/combat/combat_screen.dart';
import '../features/credits/credits_screen.dart';
import '../features/fighters/fighter_detail_screen.dart';
import '../features/fighters/fighters_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/showcase/showcase_screen.dart';

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
    initialLocation: '/accueil',
    refreshListenable: listenable,
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final onAuthPage = state.matchedLocation == '/connexion' || state.matchedLocation == '/inscription';
      if (!loggedIn && !onAuthPage) return '/connexion';
      if (loggedIn && onAuthPage) return '/accueil';
      return null;
    },
    routes: [
      GoRoute(path: '/connexion', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/inscription', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/reglages', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/credits', builder: (_, _) => const CreditsScreen()),
      GoRoute(path: '/vitrine', builder: (_, _) => const ShowcaseScreen()),
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
                  builder: (_, s) => BinderScreen(editionId: s.pathParameters['editionId']!),
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
                  builder: (_, s) => FighterDetailScreen(fighterId: s.pathParameters['id']!),
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
