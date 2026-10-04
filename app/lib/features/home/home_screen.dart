import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../auth/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final fighters = ref.watch(fightersProvider).value ?? const [];
    final editions = ref.watch(editionsProvider).value ?? const [];
    final sync = ref.watch(syncControllerProvider);
    final champions = fighters.where((f) => f.championActuel).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? 'Octogone' : 'Salut ${profile.pseudo} !'),
        actions: [
          IconButton(
            tooltip: 'Synchroniser',
            onPressed: sync.running ? null : () => ref.read(syncControllerProvider.notifier).sync(),
            icon: sync.running
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncControllerProvider.notifier).sync(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SyncCard(status: sync),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _StatTile(icon: Icons.people_alt, value: '${fighters.length}', label: 'combattants')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(icon: Icons.emoji_events, value: '$champions', label: 'champions')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatTile(icon: Icons.collections_bookmark, value: '${editions.length}', label: 'éditions')),
            ]),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.collections_bookmark,
              title: 'Parcourir les éditions',
              subtitle: 'Checklists réelles, inserts et parallèles',
              onTap: () => context.go('/album'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.people_alt,
              title: 'Tous les combattants',
              subtitle: 'Stats réelles et stats de jeu',
              onTap: () => context.go('/combattants'),
            ),
            const SizedBox(height: 12),
            const _ActionCard(
              icon: Icons.card_giftcard,
              title: 'Booster quotidien',
              subtitle: 'Arrive avec la phase 3',
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM à HH:mm', 'fr_FR');
    final (icon, color, text) = status.running
        ? (Icons.sync, AppColors.steel, 'Synchronisation du contenu…')
        : status.error != null
            ? (Icons.cloud_off, AppColors.warning, 'Hors ligne : contenu en cache')
            : status.lastSync != null
                ? (Icons.cloud_done, AppColors.success,
                    'À jour (${fmt.format(status.lastSync!)})${status.received > 0 ? ' · ${status.received} éléments reçus' : ''}')
                : (Icons.cloud_queue, AppColors.steel, 'En attente de synchronisation');
    return Card(
      child: ListTile(leading: Icon(icon, color: color), title: Text(text, style: const TextStyle(fontSize: 14))),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, this.onTap, this.enabled = true});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1 : .5,
        child: Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(icon, color: AppColors.gold, size: 32),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle),
            trailing: enabled ? const Icon(Icons.chevron_right) : null,
            onTap: enabled ? onTap : null,
          ),
        ),
      );
}
