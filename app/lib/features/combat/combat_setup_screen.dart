import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../cards/trading_card.dart';
import '../collection/owned_card_picker.dart';
import 'combat_service.dart';
import 'combat_session.dart';
import 'combat_widgets.dart';

/// Préparation d'un combat rapide : combattant, adversaire, niveau de l'IA,
/// format, catégorie, commandes et cartes Tactique.
class CombatSetupScreen extends ConsumerStatefulWidget {
  const CombatSetupScreen({super.key});

  @override
  ConsumerState<CombatSetupScreen> createState() => _CombatSetupScreenState();
}

class _CombatSetupScreenState extends ConsumerState<CombatSetupScreen> {
  final _rng = math.Random();
  String? _ownedId;
  String? _opponentId;
  final _tactics = <TacticKind>{};

  Future<void> _pickFighter() async {
    final l = context.l10n;
    final o = await pickOwnedCard(context, title: l.combatPickFighter, where: isFightCard);
    if (o != null) {
      setState(() {
        _ownedId = o.id;
        _opponentId = null;
      });
    }
  }

  Future<void> _chooseOpponent(List<Fighter> pool) async {
    final f = await chooseFighter(context, pool);
    if (f != null) setState(() => _opponentId = f.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(combatPrefsProvider);
    final cards = fightCards(ref);
    final mine = cards.firstWhereOrNull((v) => v.owned?.id == _ownedId) ?? cards.firstOrNull;
    final fighters = ref.watch(fightersProvider).value ?? const <Fighter>[];

    Fighter? opponent;
    List<Fighter> pool = const [];
    if (mine != null) {
      pool = eligibleOpponents(fighters, mine.fighter!, openWeight: prefs.openWeight);
      opponent = pool.firstWhereOrNull((f) => f.id == _opponentId);
      if (opponent == null) {
        opponent = randomOpponent(pool, mine.fighter!, _rng);
        _opponentId = opponent?.id;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.combatQuick)),
      body: mine == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.combatNoFighter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Corner(
                        label: l.combatYourFighter,
                        color: AppColors.crimson,
                        footer: TextButton.icon(
                          onPressed: _pickFighter,
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: Text(l.combatPickFighter, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        child: GestureDetector(
                          key: const Key('combat-pick-fighter'),
                          onTap: _pickFighter,
                          child: TradingCard(view: mine, animate: false),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 110, left: 6, right: 6),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: kDisplayFont,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Corner(
                        label: l.combatOpponent,
                        color: const Color(0xFF4F8DFF),
                        footer: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              key: const Key('combat-reroll'),
                              tooltip: l.combatReroll,
                              onPressed: pool.length < 2
                                  ? null
                                  : () => setState(() {
                                      final others = pool.where((f) => f.id != _opponentId).toList();
                                      _opponentId = (randomOpponent(others, mine.fighter!, _rng) ?? opponent)?.id;
                                    }),
                              icon: const Icon(Icons.casino_outlined),
                            ),
                            IconButton(
                              tooltip: l.combatChooseOpponent,
                              onPressed: pool.isEmpty ? null : () => _chooseOpponent(pool),
                              icon: const Icon(Icons.list),
                            ),
                          ],
                        ),
                        child: opponent == null
                            ? const AspectRatio(
                                aspectRatio: kCardAspect,
                                child: Center(child: Icon(Icons.help_outline)),
                              )
                            : OpponentCard(fighter: opponent, rarity: mine.rarity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CombatOptions(showWeight: true, onWeightChanged: () => setState(() => _opponentId = null)),
                TacticChooser(
                  selected: _tactics,
                  onChanged: (k) => setState(
                    () => _tactics
                      ..clear()
                      ..addAll(k),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('combat-enter'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  icon: const Icon(Icons.sports_mma),
                  label: Text(
                    l.combatEnter.toUpperCase(),
                    style: const TextStyle(fontFamily: kDisplayFont, fontSize: 17, letterSpacing: 1.2),
                  ),
                  onPressed: opponent == null
                      ? null
                      : () async {
                          final setup = CombatSetup(
                            player: Contender(
                              fighter: mine.fighter!,
                              rarity: mine.rarity,
                              bonus: mine.variant.bonusStats,
                              owned: mine.owned,
                            ),
                            opponent: Contender(
                              fighter: opponent!,
                              rarity: mine.rarity,
                              bonus: mine.rarity.defaultStatBonus,
                            ),
                            level: prefs.level,
                            format: prefs.format,
                            openWeight: prefs.openWeight,
                            tactics: chosenTactics(ref, _tactics),
                            control: prefs.control,
                            timer: prefs.timer,
                            seed: CombatSetup.newSeed(),
                          );
                          final ready = await ref.read(combatServiceProvider).prepare(setup);
                          if (context.mounted) unawaited(context.push('/arene', extra: ready));
                        },
                ),
              ],
            ),
    );
  }
}
