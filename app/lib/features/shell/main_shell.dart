import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../widgets/arena_background.dart';
import '../../widgets/octagon_emblem.dart';
import '../auth/auth_providers.dart';
import '../boosters/booster_service.dart';

/// Index de l'onglet Compte (profil), ouvert depuis le menu.
const _accountBranch = 4;

/// Barre de navigation principale + menu latéral + synchronisation du
/// contenu au démarrage. La dernière icône ouvre le menu (glisse de la droite).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _scaffold = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncControllerProvider.notifier).sync());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      key: _scaffold,
      endDrawer: MenuDrawer(
        onAccount: () => widget.shell.goBranch(_accountBranch, initialLocation: true),
        onShop: () => context.push('/boutique'),
      ),
      // Ambiance commune à tous les onglets : forte sur l'accueil, discrète ailleurs
      body: Stack(fit: StackFit.expand, children: [
        ArenaBackground(intensity: widget.shell.currentIndex == 0 ? 1 : 0.12),
        widget.shell,
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) {
          if (i == _accountBranch) {
            _scaffold.currentState?.openEndDrawer();
          } else {
            widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex);
          }
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(
              icon: const Icon(Icons.collections_bookmark_outlined),
              selectedIcon: const Icon(Icons.collections_bookmark),
              label: l.navAlbum),
          NavigationDestination(
              icon: const Icon(Icons.people_alt_outlined), selectedIcon: const Icon(Icons.people_alt), label: l.navFighters),
          NavigationDestination(
              icon: const Icon(Icons.sports_mma_outlined), selectedIcon: const Icon(Icons.sports_mma), label: l.navFight),
          NavigationDestination(
              key: const Key('nav-menu'), icon: const Icon(Icons.menu), selectedIcon: const Icon(Icons.menu_open), label: l.navMenu),
        ],
      ),
    );
  }
}

/// Menu latéral (glisse de la droite) : Compte, Boutique et solde de pièces
/// (qui ouvre aussi la Boutique).
class MenuDrawer extends ConsumerStatefulWidget {
  const MenuDrawer({super.key, required this.onAccount, required this.onShop});
  final VoidCallback onAccount;
  final VoidCallback onShop;

  @override
  ConsumerState<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends ConsumerState<MenuDrawer> {
  VoidCallback get onAccount => widget.onAccount;
  VoidCallback get onShop => widget.onShop;

  @override
  void initState() {
    super.initState();
    // Solde à jour à chaque ouverture du menu
    Future.microtask(() => ref.invalidate(walletProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final wallet = ref.watch(walletProvider).value;
    void go(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      width: 300,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(24))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const OctagonEmblem(size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile?.pseudo ?? l.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: kDisplayFont, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            // Solde : toucher les pièces ouvre la Boutique
            Material(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: const Key('menu-coins'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => go(onShop),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.toll, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(wallet == null ? '–' : '${wallet.pieces}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const Spacer(),
                    const Icon(Icons.diamond_outlined, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 6),
                    Text(wallet == null ? '–' : '${wallet.fragments}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _MenuItem(key: const Key('menu-account'), icon: Icons.person_outline, label: l.menuAccount, onTap: () => go(onAccount)),
            _MenuItem(key: const Key('menu-shop'), icon: Icons.storefront_outlined, label: l.menuShop, onTap: () => go(onShop)),
          ]),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: AppColors.gold),
        title: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      );
}
