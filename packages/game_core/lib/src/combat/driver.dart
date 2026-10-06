/// Déroulé d'un combat joueur contre IA, partagé par l'app et le serveur.
///
/// L'IA agit toujours aux mêmes moments (carte Tactique en début d'échange,
/// action après celle du joueur, réussite au mini-jeu de soumission) : le
/// serveur rejoue le journal avec [CombatDriver.replay] et retrouve
/// exactement le même combat, ou détecte une triche.
library;

import '../cards/rarity.dart';
import 'actions.dart';
import 'ai.dart';
import 'engine.dart';
import 'fighter.dart';
import 'rng.dart';
import 'tactics.dart';

class CombatDriver {
  CombatDriver(
    this.config,
    CombatFighter player,
    CombatFighter opponent, {
    required this.level,
    HabitProfile? habits,
    List<TacticCard>? opponentTactics,
  })  : engine = CombatEngine(config, player, opponent),
        ai = CombatAi(level, 1, seed: config.seed, habits: habits),
        opponentTactics = opponentTactics ?? aiTactics(level, config.seed) {
    _startExchange();
  }

  final CombatConfig config;
  final AiLevel level;
  final CombatEngine engine;
  final CombatAi ai;

  /// Cartes Tactique de l'IA (selon son niveau).
  final List<TacticCard> opponentTactics;

  final List<CombatEvent> _events = [];

  /// Dernière action jouée par l'IA.
  CombatAction? lastAiAction;

  bool get finished => engine.finished;
  CombatResult? get result => engine.result;
  PendingSubmission? get pending => engine.pending;

  /// Événements survenus depuis le dernier appel (pour l'affichage).
  List<CombatEvent> takeEvents() {
    final out = List<CombatEvent>.of(_events);
    _events.clear();
    return out;
  }

  /// Début d'échange : l'IA joue éventuellement une carte Tactique.
  void _startExchange() {
    if (engine.finished || engine.pending != null) return;
    final t = ai.pickTactic(engine, opponentTactics);
    if (t != null) _events.addAll(engine.useTactic(1, t));
  }

  /// Le joueur joue une carte Tactique (avant de choisir son action).
  void useTactic(TacticCard card) => _events.addAll(engine.useTactic(0, card));

  /// Le joueur joue [action] ; l'IA répond. Renvoie l'action de l'IA.
  CombatAction play(CombatAction action) {
    final playerStance = engine.stanceOf(0);
    final b = ai.choose(engine);
    _events.addAll(engine.play(action, b));
    ai.observe(playerStance, action);
    lastAiAction = b;
    _startExchange();
    return b;
  }

  /// Fin du mini-jeu de soumission : [playerSkill] (0..1) est la réussite du
  /// joueur, qu'il attaque ou se défende.
  void resolveSubmission(double playerSkill) {
    final p = engine.pending;
    if (p == null) throw StateError('Aucune soumission en cours');
    final aiSkill = ai.submissionSkill();
    _events.addAll(p.attacker == 0
        ? engine.resolveSubmission(attackerSkill: playerSkill, defenderSkill: aiSkill)
        : engine.resolveSubmission(attackerSkill: aiSkill, defenderSkill: playerSkill));
    _startExchange();
  }

  /// Cartes Tactique de l'IA : aucune en facile, 2 Communes en normal, 2 Rares
  /// en difficile (effets tirés selon la graine).
  static List<TacticCard> aiTactics(AiLevel level, int seed) {
    if (level == AiLevel.facile) return const [];
    final rng = CombatRng(seed ^ 0x7ac71c5);
    final kinds = [...TacticKind.values];
    final a = kinds.removeAt(rng.nextInt(kinds.length));
    final b = kinds[rng.nextInt(kinds.length)];
    final r = level == AiLevel.difficile ? Rarity.rare : Rarity.commune;
    return [TacticCard(a, r), TacticCard(b, r)];
  }

  /// Rejoue un journal envoyé par l'app : les choix du joueur sont repris
  /// tels quels, ceux de l'IA recalculés. Renvoie le résultat si le journal
  /// correspond exactement au combat recalculé (sinon null : journal
  /// incomplet, modifié ou carte Tactique non déclarée).
  static CombatResult? replay(
    CombatConfig config,
    CombatFighter player,
    CombatFighter opponent, {
    required AiLevel level,
    required List<Map<String, dynamic>> log,
    HabitProfile? habits,
    List<TacticCard> playerTactics = const [],
  }) {
    try {
      final d = CombatDriver(config, player, opponent, level: level, habits: habits);
      final allowed = {for (final t in playerTactics) t.kind: t};
      for (final step in log) {
        if (d.finished) return null; // entrées après la fin du combat
        switch (step['t']) {
          case 'tactique':
            if (step['s'] != 0) continue; // cartes de l'IA : rejouées d'elles-mêmes
            final card = TacticCard.fromJson((step['carte'] as Map).cast<String, dynamic>());
            final declared = allowed[card.kind];
            if (declared == null || declared.rarity != card.rarity) return null;
            d.useTactic(declared);
          case 'echange':
            d.play(CombatAction.fromKey((step['a'] as List)[0] as String));
          case 'soumission':
            final p = d.pending;
            if (p == null) return null;
            final skill = ((p.attacker == 0 ? step['a'] : step['d']) as num) / 1000;
            d.resolveSubmission(skill.toDouble());
          default:
            return null;
        }
      }
      if (!d.finished || !_sameLog(d.engine.log, log)) return null;
      return d.result;
    } on Object {
      return null; // action impossible, carte inconnue…
    }
  }

  static bool _sameLog(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _same(Object? x, Object? y) {
    if (x is Map && y is Map) {
      if (x.length != y.length) return false;
      for (final k in x.keys) {
        if (!y.containsKey(k) || !_same(x[k], y[k])) return false;
      }
      return true;
    }
    if (x is List && y is List) {
      if (x.length != y.length) return false;
      for (var i = 0; i < x.length; i++) {
        if (!_same(x[i], y[i])) return false;
      }
      return true;
    }
    if (x is num && y is num) return x == y;
    return x == y;
  }
}
