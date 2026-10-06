import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/octagon_emblem.dart';

/// Accueil du combat : les modes de jeu contre l'IA.
class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final modes = [
      (Icons.flash_on, l.combatQuick, l.combatQuickSub, '/combat/rapide'),
      (Icons.nightlife, l.combatEvening, l.combatEveningSub, null),
      (Icons.emoji_events, l.combatRoad, l.combatRoadSub, null),
      (Icons.movie_filter, l.combatScenarios, l.combatScenariosSub, null),
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
                onTap: m.$4 == null ? null : () => context.push(m.$4!),
              ),
            ).animate(delay: (70 * i).ms).fadeIn(duration: Motion.medium).slideY(begin: 0.08, end: 0),
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
