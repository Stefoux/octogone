import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../data/repositories/content_providers.dart';

/// Barre de navigation principale + synchronisation du contenu au démarrage.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncControllerProvider.notifier).sync());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
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
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l.navProfile),
        ],
      ),
    );
  }
}
