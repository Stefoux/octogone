import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart' show FinishMethod;
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../widgets/octagon_emblem.dart';
import 'combat_service.dart';
import 'combat_text.dart';

/// Accueil du combat : les modes de jeu contre l'IA.
class CombatScreen extends ConsumerStatefulWidget {
  const CombatScreen({super.key});

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen> {
  @override
  void initState() {
    super.initState();
    // Combats restés en attente de vérification (hors ligne)
    Future.microtask(() => ref.read(combatServiceProvider).flush());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final modes = [
      (Icons.flash_on, l.combatQuick, l.combatQuickSub, '/combat/rapide'),
      (Icons.nightlife, l.combatEvening, l.combatEveningSub, '/combat/soiree'),
      (Icons.emoji_events, l.combatRoad, l.combatRoadSub, '/combat/route'),
      (Icons.movie_filter, l.combatScenarios, l.combatScenariosSub, '/combat/rivalites'),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.navFight)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const Center(
            child: OctagonEmblem(size: 112, glow: true, child: Icon(Icons.sports_mma, size: 40, color: AppColors.gold)),
          ).animate().fadeIn(duration: Motion.slow).scaleXY(begin: 0.9, end: 1, curve: Motion.curve),
          const SizedBox(height: 18),
          for (final (i, m) in modes.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModeTile(
                key: Key('combat-mode-$i'),
                icon: m.$1,
                title: m.$2,
                subtitle: m.$3,
                onTap: () => context.push(m.$4),
              ),
            ).animate(delay: (70 * i).ms).fadeIn(duration: Motion.medium).slideY(begin: 0.08, end: 0),
          const _History(),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final on = onTap != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: on
              ? const BoxDecoration(gradient: LinearGradient(colors: [Color(0x26E2B04F), Color(0x08D03A48)]))
              : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: on ? AppColors.gold : AppColors.textMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 19,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: on ? AppColors.text : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                  ],
                ),
              ),
              if (on)
                const Icon(Icons.chevron_right, color: AppColors.gold)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(l.combatSoon, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Derniers combats (historique du serveur).
class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(combatHistoryProvider).value ?? const <CombatRecord>[];
    if (list.isEmpty) return const SizedBox.shrink();
    final fighters = ref.watch(fightersByIdProvider);
    final mode = {
      'rapide': l.combatQuick,
      'soiree': l.combatEvening,
      'route': l.combatRoad,
      'rivalite': l.rivalryLabel,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          l.combatHistory.toUpperCase(),
          style: const TextStyle(fontFamily: kDisplayFont, fontSize: 13, letterSpacing: 1.4, color: AppColors.gold),
        ),
        const SizedBox(height: 6),
        for (final c in list)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              c.status != 'valide' ? Icons.remove_circle_outline : (c.winner == 0 ? Icons.emoji_events : Icons.close),
              color: c.status != 'valide'
                  ? AppColors.textMuted
                  : (c.winner == 0 ? AppColors.gold : (c.winner == null ? AppColors.steel : AppColors.crimson)),
            ),
            title: Text(fighters[c.opponent]?.nom ?? c.opponent),
            subtitle: Text(
              [
                mode[c.mode] ?? c.mode,
                if (c.status == 'abandon') l.combatQuit,
                if (c.status == 'refuse') l.rewardRefused,
                if (c.method != null) methodLabel(l, FinishMethod.values.byName(c.method!)),
              ].join(' · '),
            ),
            trailing: c.coins > 0
                ? Text(
                    l.rewardCoins(c.coins),
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
      ],
    );
  }
}
