/// IA de combat en 3 niveaux. Déterministe (graine dérivée de celle du
/// combat) : le serveur peut recalculer ses choix et vérifier le journal.
library;

import '../stats/stat_formula.dart';
import 'actions.dart';
import 'engine.dart';
import 'fighter.dart';
import 'rng.dart';
import 'tactics.dart';

enum AiLevel {
  /// Joue ses cartes au hasard.
  facile,

  /// Suit le style du combattant et la situation (fatigue, adversaire touché…).
  normal,

  /// Apprend les habitudes du joueur et joue le contre.
  difficile;

  static AiLevel fromName(String? n) => values.firstWhere((l) => l.name == n, orElse: () => AiLevel.normal);
}

/// Habitudes du joueur : fréquence de chaque action selon la situation.
/// Gardées d'un combat à l'autre (sur l'appareil) et jointes au journal.
class HabitProfile {
  HabitProfile([Map<String, Map<String, double>>? counts]) : counts = counts ?? {};

  final Map<String, Map<String, double>> counts;

  void record(Stance stance, CombatAction a) {
    final m = counts.putIfAbsent(stance.name, () => {});
    // Oubli progressif : les choix récents comptent davantage
    for (final k in m.keys.toList()) {
      m[k] = m[k]! * 0.97;
    }
    m[a.key] = (m[a.key] ?? 0) + 1;
  }

  /// Probabilité estimée que le joueur choisisse chaque action de [options].
  /// [prior] : tendance connue du combattant (son style), avant toute habitude.
  Map<CombatAction, double> predict(Stance stance, List<CombatAction> options, {Map<CombatAction, double>? prior}) {
    final m = counts[stance.name] ?? const {};
    final priorTotal = prior == null ? 0.0 : options.fold<double>(0, (t, a) => t + (prior[a] ?? 0));
    double base(CombatAction a) =>
        prior == null || priorTotal == 0 ? 1.0 : (prior[a] ?? 0) / priorTotal * options.length;
    final raw = {for (final a in options) a: base(a) + (m[a.key] ?? 0) * 2};
    final total = raw.values.fold<double>(0, (a, b) => a + b);
    return {for (final e in raw.entries) e.key: e.value / total};
  }

  Map<String, dynamic> toJson() => {
    for (final e in counts.entries) e.key: {for (final c in e.value.entries) c.key: (c.value * 100).round() / 100},
  };

  static HabitProfile fromJson(Map<String, dynamic>? j) => HabitProfile({
    for (final e in (j ?? const {}).entries)
      e.key: {for (final c in (e.value as Map).entries) c.key as String: (c.value as num).toDouble()},
  });

  HabitProfile copy() => HabitProfile({for (final e in counts.entries) e.key: Map.of(e.value)});
}

class CombatAi {
  CombatAi(this.level, this.side, {required int seed, HabitProfile? habits})
    : habits = habits?.copy() ?? HabitProfile(),
      _rng = CombatRng(seed ^ 0x5bd1e995 ^ (side * 0x27d4eb2d));

  /// Valeur d'un finish pour le niveau difficile (en points de dégâts).
  static const finishValue = 40.0;

  /// Coût de la passivité (Garde, Esquive) pour le niveau difficile.
  static const passivityCost = 3.0;

  final AiLevel level;
  final int side;
  final HabitProfile habits;
  final CombatRng _rng;

  int get _me => side;
  int get _opp => 1 - side;

  /// À appeler après chaque échange avec l'action jouée par l'adversaire.
  void observe(Stance opponentStance, CombatAction opponentAction) {
    if (level == AiLevel.difficile) habits.record(opponentStance, opponentAction);
  }

  CombatAction choose(CombatEngine e) {
    final options = e.available(_me);
    switch (level) {
      case AiLevel.facile:
        // Joue n'importe quelle carte de sa main, sans tenir compte de son style
        return options[_rng.nextInt(options.length)];
      case AiLevel.normal:
        final scores = [for (final a in options) _heuristic(e, a)];
        return options[_rng.weighted([for (final s in scores) s * s])];
      case AiLevel.difficile:
        final values = [for (final a in options) _expectedValue(e, a)];
        // Le plus souvent le meilleur choix, parfois un autre (imprévisible)
        if (_rng.nextDouble() < 0.88) {
          var best = 0;
          for (var i = 1; i < values.length; i++) {
            if (values[i] > values[best]) best = i;
          }
          return options[best];
        }
        final min = values.reduce((a, b) => a < b ? a : b);
        return options[_rng.weighted([for (final v in values) (v - min) + 0.5])];
    }
  }

  double _cardWeight(CombatEngine e, CombatAction a) {
    if (a == CombatAction.garde) return 1.2;
    if (a == CombatAction.signature) return 3;
    return e.fighters[_me].cardWeight(a, e.stanceOf(_me));
  }

  double _heuristic(CombatEngine e, CombatAction a) {
    final me = e.sides[_me];
    final opp = e.sides[_opp];
    final f = e.fighters[_me];
    var s = _cardWeight(e, a);
    if (a == CombatAction.signature) s += 4;
    if (me.stamina < 25) {
      if (a == CombatAction.garde) s += 2.5;
      if (a == CombatAction.esquive) s += 1;
      if (a.heavy || a == CombatAction.takedown) s -= 1.2;
    }
    if (opp.health < 40) {
      if (a.heavy) s += 1.8;
      if (a == CombatAction.soumission && f[StatKind.soumission] > 60) s += 1.2;
    }
    if (me.health < 35 && a == CombatAction.garde) s += 1;
    if (e.stanceOf(_me) == Stance.dessous && a == CombatAction.seRelever && f.style == FighterStyle.frappeur) {
      s += 1.5;
    }
    if (opp.stamina < 25 && a == CombatAction.soumission) s += 1;
    return s < 0.1 ? 0.1 : s;
  }

  /// Valeur attendue d'une action face à la prévision des choix du joueur :
  /// ce qu'elle rapporte (dégâts, points des juges, position) moins ce que
  /// l'adversaire peut marquer en retour.
  double _expectedValue(CombatEngine e, CombatAction a) {
    final oppStance = e.stanceOf(_opp);
    final oppOptions = [...stanceActions[oppStance]!, CombatAction.garde];
    final oppFighter = e.fighters[_opp];
    final predicted = habits.predict(
      oppStance,
      oppOptions,
      prior: {for (final b in oppOptions) b: b == CombatAction.garde ? 1.0 : oppFighter.cardWeight(b, oppStance)},
    );
    final me = e.sides[_me];
    final opp = e.sides[_opp];
    var total = 0.0;
    for (final entry in predicted.entries) {
      final b = entry.key;
      total += entry.value * (_gain(e, _me, a, b) - _gain(e, _opp, b, a));
    }
    // Rester passif ne marque rien auprès des juges
    if (!a.offensive) total -= passivityCost;
    if (me.stamina < 20 && a.cost > 6) total -= 3;
    if (opp.health < 35 && a.heavy) total += 2;
    return total;
  }

  /// Ce que [side] gagne en jouant [x] face à [y].
  double _gain(CombatEngine e, int side, CombatAction x, CombatAction y) {
    final f = e.fighters[side];
    if (!x.offensive) {
      var v = x == CombatAction.garde ? 0.3 : 0.0; // un peu d'endurance récupérée
      if (x == CombatAction.garde && (y == CombatAction.frappePuissante || y == CombatAction.signature)) {
        v += 0.35 * 6; // contre
      }
      if (x == CombatAction.esquive && y.kind == ActionKind.frappe) v += 0.6;
      return v;
    }
    final p = e.successChance(side, x, y);
    final aggression = 0.6;
    // Un finish vaut le combat entier
    final finish = finishValue * e.finishChance(side, x, y);
    final isSub =
        x == CombatAction.soumission || (x == CombatAction.signature && f.signatureKind == SignatureKind.soumission);
    if (x.damage > 0 && !isSub) {
      final dmg = e.damageEstimate(side, x, y).toDouble();
      return aggression + p * (dmg + 1.5 + (x.heavy ? 2 : 0) + finish);
    }
    final positional = switch (x) {
      CombatAction.takedown => 5 + (f.style == FighterStyle.frappeur ? 0 : 5),
      CombatAction.clinch => 1 + (f.style == FighterStyle.frappeur ? 0 : 3),
      CombatAction.controle => 4.0,
      CombatAction.seRelever => f.style == FighterStyle.frappeur ? 7.0 : 3.0,
      _ => 3.0,
    };
    return aggression + p * (positional + finish);
  }

  /// Carte Tactique à jouer maintenant (ou null), parmi [cards].
  TacticCard? pickTactic(CombatEngine e, List<TacticCard> cards) {
    if (level == AiLevel.facile) return null;
    final me = e.sides[_me];
    final opp = e.sides[_opp];
    for (final c in cards) {
      if (!e.canUseTactic(_me, c.kind)) continue;
      final use = switch (c.kind) {
        TacticKind.secondSouffle => me.stamina < 35,
        TacticKind.coinDuCoach => me.health < 45,
        TacticKind.fouleEnDelire => e.fighters[_me].hasSignature && me.momentum >= 55 && me.momentum < 100,
        TacticKind.machoireDAcier => me.health < 50,
        TacticKind.instinctDeTueur => opp.health < 55,
        TacticKind.sortieDeCrise => e.stanceOf(_me) == Stance.dessous,
        TacticKind.planDeMatch => e.exchange == 1,
        TacticKind.pressionTotale => opp.stamina < 60,
      };
      if (use) return c;
    }
    return null;
  }

  /// Réussite au mini-jeu de soumission (0..1), selon le niveau.
  double submissionSkill() {
    final mean = switch (level) {
      AiLevel.facile => 0.35,
      AiLevel.normal => 0.5,
      AiLevel.difficile => 0.62,
    };
    return (mean + (_rng.nextDouble() - 0.5) * 0.24).clamp(0.0, 1.0);
  }
}

/// Fait combattre deux IA jusqu'au bout (simulations d'équilibrage, tests).
CombatResult simulateFight(
  CombatConfig config,
  CombatFighter red,
  CombatFighter blue, {
  AiLevel redLevel = AiLevel.normal,
  AiLevel blueLevel = AiLevel.normal,
  List<TacticCard> redTactics = const [],
  List<TacticCard> blueTactics = const [],
}) {
  final e = CombatEngine(config, red, blue);
  final ais = [CombatAi(redLevel, 0, seed: config.seed), CombatAi(blueLevel, 1, seed: config.seed)];
  final tactics = [redTactics, blueTactics];
  var guard = 0;
  while (!e.finished && guard++ < 500) {
    for (var s = 0; s < 2; s++) {
      final t = ais[s].pickTactic(e, tactics[s]);
      if (t != null) e.useTactic(s, t);
    }
    final stances = [e.stanceOf(0), e.stanceOf(1)];
    final a0 = ais[0].choose(e);
    final a1 = ais[1].choose(e);
    e.play(a0, a1);
    ais[0].observe(stances[1], a1);
    ais[1].observe(stances[0], a0);
    final p = e.pending;
    if (p != null) {
      e.resolveSubmission(
        attackerSkill: ais[p.attacker].submissionSkill(),
        defenderSkill: ais[1 - p.attacker].submissionSkill(),
      );
    }
  }
  return e.result!;
}
