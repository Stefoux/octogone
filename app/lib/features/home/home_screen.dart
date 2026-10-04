import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../auth/auth_providers.dart';
import 'welcome_pack.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final fighters = ref.watch(fightersProvider).value ?? const [];
    final owned = ref.watch(ownedCardsProvider).value ?? const [];
    final sync = ref.watch(syncControllerProvider);
    final champions = fighters.where((f) => f.championActuel).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? l.appTitle : l.helloUser(profile.pseudo)),
        actions: [
          IconButton(
            tooltip: l.sync,
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
            if (profile != null && !profile.welcomePackReceived) ...[
              const SizedBox(height: 12),
              const WelcomePackCard(),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _StatTile(icon: Icons.style, value: '${owned.length}', label: l.statMyCards)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(icon: Icons.people_alt, value: '${fighters.length}', label: l.statFighters)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(icon: Icons.emoji_events, value: '$champions', label: l.statChampions)),
            ]),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.collections_bookmark,
              title: l.browseEditions,
              subtitle: l.browseEditionsSub,
              onTap: () => context.go('/album'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.auto_awesome,
              title: l.effectsShowcase,
              subtitle: l.effectsShowcaseSub,
              onTap: () => context.push('/vitrine'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.people_alt,
              title: l.allFighters,
              subtitle: l.allFightersSub,
              onTap: () => context.go('/combattants'),
            ),
            const SizedBox(height: 12),
            _ActionCard(icon: Icons.card_giftcard, title: l.dailyBooster, subtitle: l.comingPhase3, enabled: false),
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
    final l = context.l10n;
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm();
    final (icon, color, text) = status.running
        ? (Icons.sync, AppColors.steel, l.syncRunning)
        : status.error != null
            ? (Icons.cloud_off, AppColors.warning, l.syncOffline)
            : status.lastSync != null
                ? (
                    Icons.cloud_done,
                    AppColors.success,
                    status.received > 0
                        ? l.syncUpToDateReceived(fmt.format(status.lastSync!), status.received)
                        : l.syncUpToDate(fmt.format(status.lastSync!)),
                  )
                : (Icons.cloud_queue, AppColors.steel, l.syncWaiting);
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
