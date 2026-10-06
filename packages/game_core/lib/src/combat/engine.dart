/// Moteur de combat tactique au tour par tour.
///
/// Chaque échange, les deux combattants choisissent une action en secret ;
/// la résolution combine une matrice d'actions ([matchup]), les stats (avec
/// le bonus de rareté) et une part d'aléatoire tirée d'un générateur à graine
/// fixe. Tout est déterministe : rejouer la même graine avec les mêmes choix
/// redonne exactement le même combat (vérification serveur).
library;

import '../stats/stat_formula.dart';
import 'actions.dart';
import 'fighter.dart';
import 'rng.dart';
import 'tactics.dart';

/// Format choisi avant le combat.
enum CombatFormat {
  /// 3 échanges par round.
  court(3),

  /// 5 échanges par round.
  complet(5);

  const CombatFormat(this.exchanges);
  final int exchanges;
}

class CombatConfig {
  const CombatConfig({
    required this.seed,
    this.format = CombatFormat.complet,
    this.titleFight = false,
    this.openWeight = false,
  });

  final int seed;
  final CombatFormat format;

  /// Combat de titre ou main event : 5 rounds au lieu de 3.
  final bool titleFight;

  /// Poids libre : combattants de catégories différentes, avec un malus pour
  /// le plus léger.
  final bool openWeight;

  int get rounds => titleFight ? 5 : 3;
  int get exchangesPerRound => format.exchanges;

  Map<String, dynamic> toJson() =>
      {'seed': seed, 'format': format.name, 'titre': titleFight, 'poids_libre': openWeight};

  static CombatConfig fromJson(Map<String, dynamic> j) => CombatConfig(
        seed: (j['seed'] as num).toInt(),
        format: CombatFormat.values.byName(j['format'] as String? ?? 'complet'),
        titleFight: j['titre'] == true,
        openWeight: j['poids_libre'] == true,
      );
}

/// Ce qui se passe pendant un échange (traduit en commentaires par l'app).
class CombatEvent {
  const CombatEvent(this.type, {this.side, this.action, this.value, this.detail});

  /// tactique, touche, rate, bloque, esquive, contre, knockdown, takedown,
  /// takedown_rate, clinch, separe, releve, controle, soumission_tentee,
  /// soumission_reussie, soumission_echappee, signature, fatigue, ko, tko,
  /// fin_round, decision.
  final String type;
  final int? side;
  final CombatAction? action;
  final int? value;
  final String? detail;

  @override
  String toString() => '$type${side == null ? '' : '[$side]'}${action == null ? '' : ' ${action!.key}'}'
      '${value == null ? '' : ' $value'}${detail == null ? '' : ' ($detail)'}';
}

enum FinishMethod { ko, tko, soumission, decisionUnanime, decisionPartagee, decisionMajoritaire, nul }

class CombatResult {
  const CombatResult({
    required this.winner,
    required this.method,
    required this.round,
    required this.exchange,
    required this.scorecards,
  });

  /// 0, 1, ou null pour un match nul.
  final int? winner;
  final FinishMethod method;
  final int round;
  final int exchange;

  /// Cartes des 3 juges : pour chaque juge, les points (rouge, bleu) de chaque round.
  final List<List<(int, int)>> scorecards;

  bool get isFinish => method == FinishMethod.ko || method == FinishMethod.tko || method == FinishMethod.soumission;

  (int, int) judgeTotal(int judge) => scorecards[judge].fold((0, 0), (a, r) => (a.$1 + r.$1, a.$2 + r.$2));

  Map<String, dynamic> toJson() => {
        'vainqueur': winner,
        'methode': method.name,
        'round': round,
        'echange': exchange,
        'juges': [for (final j in scorecards) [for (final r in j) [r.$1, r.$2]]],
      };
}

/// État d'un combattant pendant le combat.
class SideState {
  SideState({this.maxHealth = 100, this.momentum = 0}) : health = maxHealth;

  /// Santé maximale : 100, plus un petit bonus selon la rareté de la carte.
  final int maxHealth;
  int health;
  int stamina = 100;
  int momentum;
  final Map<Stance, List<CombatAction>> hands = {};
  final List<TacticKind> tacticsUsed = [];
  int shieldTurns = 0;
  double shieldPct = 0;
  int boostTurns = 0;
  double boostPct = 0;
  int focusTurns = 0;
  double focusPct = 0;
  double dodgeFocus = 0;
  bool escapeReady = false;
}

/// Statistiques d'un round pour les juges.
class _RoundStats {
  final damage = [0, 0];
  final landed = [0, 0];
  final knockdowns = [0, 0];
  final control = [0, 0];
  final top = [0, 0];
  final takedowns = [0, 0];
  final aggression = [0, 0];
  final subAttempts = [0, 0];
}

/// Soumission engagée, en attente du mini-jeu.
class PendingSubmission {
  const PendingSubmission(this.attacker, this.signature);
  final int attacker;
  final bool signature;
}

class CombatEngine {
  CombatEngine(this.config, CombatFighter red, CombatFighter blue)
      : fighters = [red, blue],
        sides = [_side(red), _side(blue)],
        _rng = CombatRng(config.seed) {
    for (var s = 0; s < 2; s++) {
      _drawHand(s, Stance.debout);
    }
    _newRoundStats();
  }

  static const handSize = 4;
  static const maxTactics = 2;

  final CombatConfig config;
  final List<CombatFighter> fighters;
  final CombatRng _rng;
  final List<SideState> sides;

  /// Avantage de rareté, en plus du bonus de stats : +6 santé, +8 momentum de
  /// départ et +1 % de réussite par rang (Commune +0 … Mythique +30 santé).
  static SideState _side(CombatFighter f) =>
      SideState(maxHealth: 100 + 6 * f.rarity.index, momentum: 8 * f.rarity.index);

  Position position = Position.debout;

  /// Au sol : qui est dessus (0 ou 1).
  int? top;
  int round = 1;
  int exchange = 1;
  CombatResult? result;
  PendingSubmission? pending;
  final List<_RoundStats> _rounds = [];

  /// Journal des choix (rejoué par le serveur).
  final List<Map<String, dynamic>> log = [];

  bool get finished => result != null;

  // --- Situation et cartes ----------------------------------------------------

  Stance stanceOf(int side) => switch (position) {
        Position.debout => Stance.debout,
        Position.clinch => Stance.clinch,
        Position.sol => top == side ? Stance.dessus : Stance.dessous,
      };

  void _drawHand(int side, Stance stance) {
    final hand = sides[side].hands.putIfAbsent(stance, () => []);
    while (hand.length < handSize) {
      hand.add(fighters[side].drawCard(stance, _rng));
    }
  }

  /// Main de cartes de la situation actuelle (4 cartes).
  List<CombatAction> hand(int side) {
    final st = stanceOf(side);
    _drawHand(side, st);
    return List.unmodifiable(sides[side].hands[st]!);
  }

  /// Le coup signature est-il jouable maintenant ?
  bool signatureReady(int side) {
    final f = fighters[side];
    if (!f.hasSignature || sides[side].momentum < 100) return false;
    final st = stanceOf(side);
    return f.signatureKind == SignatureKind.frappe
        ? (st == Stance.debout || st == Stance.clinch)
        : (st == Stance.dessus || st == Stance.dessous);
  }

  /// Actions jouables : la main, la Garde (toujours), le coup signature.
  List<CombatAction> available(int side) => [
        ...{...hand(side)},
        CombatAction.garde,
        if (signatureReady(side)) CombatAction.signature,
      ];

  bool canUseTactic(int side, TacticKind kind) =>
      !finished &&
      pending == null &&
      sides[side].tacticsUsed.length < maxTactics &&
      !sides[side].tacticsUsed.contains(kind);

  // --- Cartes Tactique ----------------------------------------------------------

  List<CombatEvent> useTactic(int side, TacticCard card) {
    if (!canUseTactic(side, card.kind)) throw StateError('Carte Tactique non utilisable');
    log.add({'t': 'tactique', 's': side, 'carte': card.toJson()});
    final me = sides[side];
    final other = sides[1 - side];
    me.tacticsUsed.add(card.kind);
    final a = card.amount;
    switch (card.kind) {
      case TacticKind.secondSouffle:
        me.stamina = (me.stamina + a.toInt()).clamp(0, 100);
      case TacticKind.coinDuCoach:
        me.health = (me.health + a.toInt()).clamp(0, me.maxHealth);
      case TacticKind.fouleEnDelire:
        me.momentum = (me.momentum + a.toInt()).clamp(0, 100);
      case TacticKind.machoireDAcier:
        me.shieldTurns = 2;
        me.shieldPct = a.toDouble();
      case TacticKind.instinctDeTueur:
        me.boostTurns = 2;
        me.boostPct = a.toDouble();
      case TacticKind.sortieDeCrise:
        me.escapeReady = true;
        me.stamina = (me.stamina + a.toInt()).clamp(0, 100);
      case TacticKind.planDeMatch:
        me.focusTurns = 2;
        me.focusPct = a.toDouble();
      case TacticKind.pressionTotale:
        other.stamina = (other.stamina - a.toInt()).clamp(0, 100);
    }
    return [CombatEvent('tactique', side: side, value: a is int ? a : (a * 100).round(), detail: card.kind.key)];
  }

  // --- Échange ------------------------------------------------------------------

  double _s(int side, StatKind k) => fighters[side][k] / 99.0;

  /// Rapport de poids (poids libre) : > 1 si [side] est plus lourd.
  double _sizeRatio(int side) {
    if (!config.openWeight) return 1;
    final a = fighters[side].weightClass?.limitKg;
    final b = fighters[1 - side].weightClass?.limitKg;
    if (a == null || b == null) return 1;
    return a / b;
  }

  double _fatigue(int side) {
    final st = sides[side].stamina;
    if (st < 10) return 0.20;
    if (st < 25) return 0.10;
    return 0;
  }

  double _edge(int i, int j, CombatAction a) {
    switch (a) {
      case CombatAction.frappeRapide:
        return (_s(i, StatKind.frappe) - _s(j, StatKind.defense)) * 0.5;
      case CombatAction.frappePuissante:
      case CombatAction.coupDePied:
      case CombatAction.groundAndPound:
        return ((_s(i, StatKind.frappe) + _s(i, StatKind.puissance)) / 2 - _s(j, StatKind.defense)) * 0.5;
      case CombatAction.takedown:
      case CombatAction.clinch:
        return (_s(i, StatKind.lutte) - _s(j, StatKind.lutte)) * 0.6 + (_sizeRatio(i) - 1) * 0.4;
      case CombatAction.soumission:
        return (_s(i, StatKind.soumission) - _s(j, StatKind.soumission)) * 0.5;
      case CombatAction.controle:
        return (_s(i, StatKind.lutte) - _s(j, StatKind.lutte)) * 0.5 + (_sizeRatio(i) - 1) * 0.3;
      case CombatAction.seRelever:
        return ((_s(i, StatKind.lutte) * 0.6 + _s(i, StatKind.cardio) * 0.4) - _s(j, StatKind.lutte)) * 0.5;
      case CombatAction.signature:
        return fighters[i].signatureKind == SignatureKind.frappe
            ? ((_s(i, StatKind.frappe) + _s(i, StatKind.puissance)) / 2 - _s(j, StatKind.defense)) * 0.5
            : (_s(i, StatKind.soumission) - _s(j, StatKind.soumission)) * 0.5;
      default:
        return 0;
    }
  }

  double _chance(int i, int j, CombatAction a, CombatAction b) {
    final me = sides[i];
    if (a == CombatAction.seRelever && me.escapeReady) return 1;
    // Se relever volontairement quand on est dessus : toujours possible
    if (a == CombatAction.seRelever && stanceOf(i) == Stance.dessus) return 1;
    var p = a.base + matchup(a, b, stanceOf(i)) + _edge(i, j, a) - _fatigue(i) + me.dodgeFocus;
    p += 0.01 * fighters[i].rarity.index;
    if (fighters[i].style == FighterStyle.complet) p += 0.03; // lecture du combat
    if (me.focusTurns > 0) p += me.focusPct;
    return p.clamp(0.05, 0.95);
  }

  int _damage(int i, int j, CombatAction a, CombatAction b) {
    final strikeKind = a == CombatAction.signature ? CombatAction.frappePuissante : a;
    double power;
    if (strikeKind == CombatAction.frappeRapide) {
      power = 0.7 + 0.6 * _s(i, StatKind.frappe);
    } else {
      power = 0.55 + 0.9 * _s(i, StatKind.puissance);
    }
    final chin = 1.3 - 0.6 * _s(j, StatKind.menton);
    var d = a.damage * power * chin;
    if (b == CombatAction.garde) d *= 0.6;
    if (config.openWeight) {
      final r = _sizeRatio(i);
      d *= (0.5 + 0.5 * r).clamp(0.75, 1.35);
    }
    final me = sides[i];
    final other = sides[j];
    if (me.boostTurns > 0) d *= 1 + me.boostPct;
    if (other.shieldTurns > 0) d *= 1 - other.shieldPct;
    final st = me.stamina;
    if (st < 10) {
      d *= 0.7;
    } else if (st < 25) {
      d *= 0.85;
    }
    final out = d.round();
    return out < 1 ? 1 : out;
  }

  /// Chance de réussite de l'action [a] de [side] face à [b] (sans tirage) : pour l'IA.
  double successChance(int side, CombatAction a, CombatAction b) =>
      a.offensive ? _chance(side, 1 - side, a, b) : 0;

  /// Dégâts estimés d'une frappe réussie (sans tirage) : pour l'IA.
  int damageEstimate(int side, CombatAction a, CombatAction b) => _damage(side, 1 - side, a, b);

  _RoundStats get _rs => _rounds.last;

  void _newRoundStats() => _rounds.add(_RoundStats());

  void _gainMomentum(int side, int amount) =>
      sides[side].momentum = (sides[side].momentum + amount).clamp(0, 100);

  /// Joue un échange : action de rouge (0) et de bleu (1).
  /// [skillRed] / [skillBlue] ne servent qu'aux soumissions automatiques
  /// (simulations) ; l'app passe par [resolveSubmission] après le mini-jeu.
  List<CombatEvent> play(CombatAction red, CombatAction blue) {
    if (finished) throw StateError('Combat terminé');
    if (pending != null) throw StateError('Soumission en attente du mini-jeu');
    final acts = [red, blue];
    for (var s = 0; s < 2; s++) {
      if (!available(s).contains(acts[s])) {
        throw ArgumentError('Action ${acts[s].key} non disponible pour le combattant $s');
      }
    }
    log.add({'t': 'echange', 'a': [red.key, blue.key]});
    final ev = <CombatEvent>[];
    final stances = [stanceOf(0), stanceOf(1)];

    // 1. Endurance et cartes jouées (remplacées)
    for (var s = 0; s < 2; s++) {
      final a = acts[s];
      sides[s].stamina = (sides[s].stamina - a.cost).clamp(0, 100);
      final hand = sides[s].hands[stances[s]]!;
      final idx = hand.indexOf(a);
      if (idx >= 0) {
        hand.removeAt(idx);
        hand.add(fighters[s].drawCard(stances[s], _rng));
      }
      if (a == CombatAction.signature) {
        sides[s].momentum = 0;
        ev.add(CombatEvent('signature', side: s, detail: fighters[s].signatureKind.name));
      }
      if (a.offensive) _rs.aggression[s]++;
      if (_fatigue(s) > 0 && a.offensive) ev.add(CombatEvent('fatigue', side: s));
    }

    // 2. Réussite de chaque action offensive
    final success = [false, false];
    final rolls = [1.0, 1.0];
    for (var s = 0; s < 2; s++) {
      final a = acts[s];
      if (!a.offensive) continue;
      final p = _chance(s, 1 - s, a, acts[1 - s]);
      rolls[s] = _rng.nextDouble();
      success[s] = rolls[s] < p;
    }
    for (var s = 0; s < 2; s++) {
      sides[s].dodgeFocus = 0;
    }

    // 3. Frappes (et contres)
    for (var s = 0; s < 2 && !finished; s++) {
      final a = acts[s];
      final o = 1 - s;
      final b = acts[o];
      final strike = a.kind == ActionKind.frappe ||
          (a == CombatAction.signature && fighters[s].signatureKind == SignatureKind.frappe);
      if (!strike) continue;
      if (success[s]) {
        final dmg = _damage(s, o, a, b);
        sides[o].health -= dmg;
        _rs.damage[s] += dmg;
        _rs.landed[s]++;
        ev.add(CombatEvent(b == CombatAction.garde ? 'bloque' : 'touche', side: s, action: a, value: dmg));
        _gainMomentum(s, a.heavy ? 12 : 7);
        _gainMomentum(o, a.heavy ? -8 : -4);
        if (a.heavy) _knockdownCheck(s, o, dmg, a, ev);
        if (!finished && sides[o].health <= 0) {
          sides[o].health = 0;
          _finish(s, a == CombatAction.groundAndPound ? FinishMethod.tko : FinishMethod.ko, ev);
        }
      } else {
        if (b == CombatAction.esquive) {
          ev.add(CombatEvent('esquive', side: o, action: a));
          _gainMomentum(o, 8);
          sides[o].dodgeFocus = 0.08;
        } else if (b == CombatAction.garde) {
          ev.add(CombatEvent('bloque', side: s, action: a, value: 0));
          _gainMomentum(o, 5);
        } else {
          ev.add(CombatEvent('rate', side: s, action: a));
        }
      }
      // Contre : la Garde punit la Frappe puissante
      if (!finished &&
          b == CombatAction.garde &&
          (a == CombatAction.frappePuissante || a == CombatAction.signature) &&
          stances[o] != Stance.dessous) {
        final p = (0.35 + (fighters[o][StatKind.frappe] - fighters[s][StatKind.frappe]) / 200).clamp(0.1, 0.7);
        if (_rng.nextDouble() < p) {
          final dmg = (10 * (0.7 + 0.6 * _s(o, StatKind.frappe)) * (1.3 - 0.6 * _s(s, StatKind.menton))).round();
          sides[s].health -= dmg;
          _rs.damage[o] += dmg;
          _rs.landed[o]++;
          ev.add(CombatEvent('contre', side: o, value: dmg));
          _gainMomentum(o, 10);
          if (sides[s].health <= 0) {
            sides[s].health = 0;
            _finish(o, FinishMethod.ko, ev);
          }
        }
      }
    }

    if (!finished) _resolvePosition(acts, stances, success, rolls, ev);
    if (!finished) _endExchange(ev);
    return ev;
  }

  void _knockdownCheck(int s, int o, int dmg, CombatAction a, List<CombatEvent> ev) {
    final menton = _s(o, StatKind.menton);
    final hurt = 1 + (sides[o].maxHealth - sides[o].health) / 120;
    var kd = 0.04 + dmg / 45 * (1.3 - menton) * hurt;
    if (a == CombatAction.signature) kd *= 1.8;
    if (a == CombatAction.groundAndPound) kd *= 0.6;
    if (_rng.nextDouble() < kd.clamp(0, 0.6)) {
      _rs.knockdowns[s]++;
      _gainMomentum(s, 20);
      ev.add(CombatEvent('knockdown', side: s, action: a));
      final ko = 0.32 + (1 - sides[o].health / sides[o].maxHealth) * 0.6 - menton * 0.15;
      if (_rng.nextDouble() < ko.clamp(0.05, 0.85)) {
        _finish(s, a == CombatAction.groundAndPound ? FinishMethod.tko : FinishMethod.ko, ev);
      }
    }
  }

  void _resolvePosition(List<CombatAction> acts, List<Stance> stances, List<bool> success, List<double> rolls,
      List<CombatEvent> ev) {
    // Contrôle
    final pinned = [false, false];
    for (var s = 0; s < 2; s++) {
      if (acts[s] == CombatAction.controle) {
        if (success[s]) {
          _rs.control[s]++;
          sides[1 - s].stamina = (sides[1 - s].stamina - 5).clamp(0, 100);
          _gainMomentum(s, 5);
          pinned[1 - s] = true;
          ev.add(CombatEvent('controle', side: s));
        } else {
          ev.add(CombatEvent('rate', side: s, action: CombatAction.controle));
        }
      }
    }
    // Soumissions (y compris la signature soumission)
    for (var s = 0; s < 2; s++) {
      final a = acts[s];
      final isSub = a == CombatAction.soumission ||
          (a == CombatAction.signature && fighters[s].signatureKind == SignatureKind.soumission);
      if (!isSub) continue;
      _rs.subAttempts[s]++;
      if (success[s] && pending == null) {
        pending = PendingSubmission(s, a == CombatAction.signature);
        ev.add(CombatEvent('soumission_tentee', side: s, action: a));
        _gainMomentum(s, 8);
        return; // la suite dépend du mini-jeu
      } else if (!success[s]) {
        ev.add(CombatEvent('rate', side: s, action: a));
      }
    }
    // Takedowns
    final td = [
      for (var s = 0; s < 2; s++) acts[s] == CombatAction.takedown && success[s],
    ];
    for (var s = 0; s < 2; s++) {
      if (acts[s] == CombatAction.takedown && !success[s]) ev.add(CombatEvent('takedown_rate', side: s));
    }
    if (td[0] || td[1]) {
      int winner;
      if (td[0] && td[1]) {
        // Échange de takedowns : le meilleur lutteur finit dessus
        final m0 = _s(0, StatKind.lutte) + (1 - rolls[0]) * 0.3;
        final m1 = _s(1, StatKind.lutte) + (1 - rolls[1]) * 0.3;
        winner = m0 >= m1 ? 0 : 1;
      } else {
        winner = td[0] ? 0 : 1;
      }
      position = Position.sol;
      top = winner;
      _rs.takedowns[winner]++;
      _gainMomentum(winner, 12);
      ev.add(CombatEvent('takedown', side: winner));
      return;
    }
    // Se relever / se dégager
    for (var s = 0; s < 2; s++) {
      if (acts[s] != CombatAction.seRelever) continue;
      final ok = (success[s] || stances[s] == Stance.dessus || sides[s].escapeReady) &&
          !(pinned[s] && !sides[s].escapeReady);
      if (ok && position != Position.debout) {
        if (sides[s].escapeReady) sides[s].escapeReady = false;
        ev.add(CombatEvent(position == Position.clinch ? 'separe' : 'releve', side: s));
        position = Position.debout;
        top = null;
        return;
      } else if (!ok) {
        ev.add(CombatEvent('rate', side: s, action: CombatAction.seRelever));
      }
    }
    // Clinch
    for (var s = 0; s < 2; s++) {
      if (acts[s] == CombatAction.clinch) {
        if (success[s] && position == Position.debout) {
          position = Position.clinch;
          ev.add(CombatEvent('clinch', side: s));
          return;
        } else if (!success[s]) {
          ev.add(CombatEvent('rate', side: s, action: CombatAction.clinch));
        }
      }
    }
  }

  /// Résout la soumission engagée. [attackerSkill] / [defenderSkill] (0..1) :
  /// réussite des mini-jeux (timing pour attaquer, appuis rapides pour se
  /// dégager).
  List<CombatEvent> resolveSubmission({required double attackerSkill, required double defenderSkill}) {
    final p = pending;
    if (p == null) throw StateError('Aucune soumission en cours');
    final a = attackerSkill.clamp(0.0, 1.0);
    final d = defenderSkill.clamp(0.0, 1.0);
    log.add({'t': 'soumission', 'a': (a * 1000).round(), 'd': (d * 1000).round()});
    final s = p.attacker;
    final o = 1 - s;
    final ev = <CombatEvent>[];
    var chance = 0.36 +
        (_s(s, StatKind.soumission) - _s(o, StatKind.soumission)) * 0.8 +
        (p.signature ? 0.15 : 0) +
        (1 - sides[o].stamina / 100) * 0.15 +
        (1 - sides[o].health / sides[o].maxHealth) * 0.10 +
        0.35 * ((a * 1000).round() / 1000 - 0.5) -
        0.35 * ((d * 1000).round() / 1000 - 0.5);
    pending = null;
    if (_rng.nextDouble() < chance.clamp(0.03, 0.85)) {
      ev.add(CombatEvent('soumission_reussie', side: s));
      _finish(s, FinishMethod.soumission, ev);
    } else {
      ev.add(CombatEvent('soumission_echappee', side: o));
      _gainMomentum(o, 10);
      sides[o].stamina = (sides[o].stamina - 6).clamp(0, 100);
      if (_rng.nextDouble() < 0.35) {
        position = Position.debout;
        top = null;
        ev.add(CombatEvent('releve', side: o));
      }
      _endExchange(ev);
    }
    return ev;
  }

  void _endExchange(List<CombatEvent> ev) {
    for (var s = 0; s < 2; s++) {
      final me = sides[s];
      if (me.shieldTurns > 0) me.shieldTurns--;
      if (me.boostTurns > 0) me.boostTurns--;
      if (me.focusTurns > 0) me.focusTurns--;
      if (position == Position.sol && top == s) _rs.top[s]++;
    }
    exchange++;
    if (exchange > config.exchangesPerRound) {
      ev.add(CombatEvent('fin_round', value: round));
      if (round >= config.rounds) {
        _decision(ev);
        return;
      }
      round++;
      exchange = 1;
      position = Position.debout;
      top = null;
      for (var s = 0; s < 2; s++) {
        final me = sides[s];
        me.stamina = (me.stamina + 15 + (25 * _s(s, StatKind.cardio)).round()).clamp(0, 100);
        me.health = (me.health + 4).clamp(0, me.maxHealth);
      }
      _newRoundStats();
    }
  }

  // --- Juges ----------------------------------------------------------------------

  /// Points d'un round pour un juge (chaque juge a sa sensibilité : dégâts,
  /// contrôle ou agressivité).
  (int, int) _scoreRound(_RoundStats r, int judge) {
    double score(int s) {
      final dmgW = judge == 0 ? 1.25 : 1.0;
      final ctrlW = judge == 1 ? 1.35 : 1.0;
      final aggrW = judge == 2 ? 1.4 : 1.0;
      return r.damage[s] * dmgW +
          r.knockdowns[s] * 12 +
          r.landed[s] * 1.5 +
          (r.control[s] * 4 + r.top[s] * 2 + r.takedowns[s] * 5) * ctrlW +
          r.aggression[s] * 0.6 * aggrW +
          r.subAttempts[s] * 3;
    }

    final noise = CombatRng(config.seed ^ (judge * 977 + _rounds.indexOf(r) * 131 + 17));
    final a = score(0) * (0.97 + 0.06 * noise.nextDouble());
    final b = score(1) * (0.97 + 0.06 * noise.nextDouble());
    final hi = a > b ? a : b;
    if (hi == 0 || (a - b).abs() < hi * 0.015) return (10, 10);
    final winner = a > b ? 0 : 1;
    final lo = winner == 0 ? b : a;
    final dmgGap = (r.damage[winner] - r.damage[1 - winner]).abs();
    // 10-8 : domination nette (knockdown et large avance, ou écart écrasant)
    final dominant = (r.knockdowns[winner] >= 2 && hi > lo * 2.0) ||
        (r.knockdowns[winner] >= 1 && dmgGap >= 35 && hi > lo * 2.8) ||
        (dmgGap >= 55 && hi > lo * 3.0);
    final loser = dominant ? 8 : 9;
    return winner == 0 ? (10, loser) : (loser, 10);
  }

  List<List<(int, int)>> _scorecards() => [
        for (var j = 0; j < 3; j++) [for (final r in _rounds) _scoreRound(r, j)],
      ];

  void _decision(List<CombatEvent> ev) {
    final cards = _scorecards();
    final votes = <int?>[];
    for (final card in cards) {
      final t = card.fold((0, 0), (a, r) => (a.$1 + r.$1, a.$2 + r.$2));
      votes.add(t.$1 == t.$2 ? null : (t.$1 > t.$2 ? 0 : 1));
    }
    final red = votes.where((v) => v == 0).length;
    final blue = votes.where((v) => v == 1).length;
    final draws = votes.where((v) => v == null).length;
    int? winner;
    FinishMethod method;
    if (red == 3 || blue == 3) {
      winner = red == 3 ? 0 : 1;
      method = FinishMethod.decisionUnanime;
    } else if ((red == 2 && blue == 1) || (blue == 2 && red == 1)) {
      winner = red == 2 ? 0 : 1;
      method = FinishMethod.decisionPartagee;
    } else if ((red == 2 || blue == 2) && draws == 1) {
      winner = red == 2 ? 0 : 1;
      method = FinishMethod.decisionMajoritaire;
    } else {
      winner = null;
      method = FinishMethod.nul;
    }
    result = CombatResult(
      winner: winner,
      method: method,
      round: config.rounds,
      exchange: config.exchangesPerRound,
      scorecards: cards,
    );
    ev.add(CombatEvent('decision', side: winner, detail: method.name));
  }

  void _finish(int winner, FinishMethod method, List<CombatEvent> ev) {
    result = CombatResult(
      winner: winner,
      method: method,
      round: round,
      exchange: exchange,
      scorecards: _scorecards(),
    );
    ev.add(CombatEvent(method == FinishMethod.soumission ? 'fin_soumission' : method.name, side: winner));
  }
}
