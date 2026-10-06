import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../../core/l10n.dart';

/// Nom d'une carte d'action (« Se relever » devient « Se dégager » au clinch).
String actionName(AppLocalizations l, CombatAction a, [Stance? stance]) => switch (a) {
  CombatAction.frappeRapide => l.actFrappeRapide,
  CombatAction.frappePuissante => l.actFrappePuissante,
  CombatAction.coupDePied => l.actCoupDePied,
  CombatAction.takedown => l.actTakedown,
  CombatAction.clinch => l.actClinch,
  CombatAction.garde => l.actGarde,
  CombatAction.esquive => l.actEsquive,
  CombatAction.groundAndPound => l.actGroundAndPound,
  CombatAction.soumission => l.actSoumission,
  CombatAction.seRelever => stance == Stance.clinch ? l.actSeDegager : l.actSeRelever,
  CombatAction.controle => l.actControle,
  CombatAction.signature => l.actSignature,
};

IconData actionIcon(CombatAction a) => switch (a) {
  CombatAction.frappeRapide => Icons.flash_on,
  CombatAction.frappePuissante => Icons.sports_mma,
  CombatAction.coupDePied => Icons.directions_walk,
  CombatAction.takedown => Icons.south,
  CombatAction.clinch => Icons.people_alt,
  CombatAction.garde => Icons.shield_outlined,
  CombatAction.esquive => Icons.swap_horiz,
  CombatAction.groundAndPound => Icons.keyboard_double_arrow_down,
  CombatAction.soumission => Icons.link,
  CombatAction.seRelever => Icons.north,
  CombatAction.controle => Icons.lock_outline,
  CombatAction.signature => Icons.auto_awesome,
};

/// Couleur d'une carte d'action selon sa famille.
Color actionColor(CombatAction a) => switch (a.kind) {
  ActionKind.frappe => const Color(0xFFE5484D),
  ActionKind.lutte => const Color(0xFF5B8CFF),
  ActionKind.defense => const Color(0xFF4CC38A),
  ActionKind.soumission => const Color(0xFFB07CFF),
  ActionKind.degagement => const Color(0xFF3FB6E8),
  ActionKind.controle => const Color(0xFF9AA7B8),
  ActionKind.signature => const Color(0xFFE8B04A),
};

String stanceLabel(AppLocalizations l, Stance s) => switch (s) {
  Stance.debout => l.combatStanceDebout,
  Stance.clinch => l.combatStanceClinch,
  Stance.dessus => l.combatStanceDessus,
  Stance.dessous => l.combatStanceDessous,
};

String levelLabel(AppLocalizations l, AiLevel a) => switch (a) {
  AiLevel.facile => l.combatLevelFacile,
  AiLevel.normal => l.combatLevelNormal,
  AiLevel.difficile => l.combatLevelDifficile,
};

String methodLabel(AppLocalizations l, FinishMethod m) => switch (m) {
  FinishMethod.ko => l.methodKo,
  FinishMethod.tko => l.methodTko,
  FinishMethod.soumission => l.methodSoumission,
  FinishMethod.decisionUnanime => l.methodDecisionUnanime,
  FinishMethod.decisionPartagee => l.methodDecisionPartagee,
  FinishMethod.decisionMajoritaire => l.methodDecisionMajoritaire,
  FinishMethod.nul => l.methodNul,
};

/// Commentaire d'un événement du moteur, ou null s'il ne se commente pas.
/// [names] : noms des deux combattants (0 = joueur, 1 = IA).
String? eventText(AppLocalizations l, CombatEvent e, List<String> names) {
  final s = e.side;
  final a = s == null ? '' : names[s];
  final b = s == null ? '' : names[1 - s];
  final act = e.action == null ? '' : actionName(l, e.action!);
  return switch (e.type) {
    'touche' => l.evTouche(a, act, e.value ?? 0),
    'bloque' => (e.value ?? 0) > 0 ? l.evBloqueTouche(b, e.value!) : l.evBloque(b, act),
    'rate' => l.evRate(a, act),
    'esquive' => l.evEsquive(a),
    'contre' => l.evContre(a, e.value ?? 0),
    'knockdown' => l.evKnockdown(a, b),
    'takedown' => l.evTakedown(a),
    'takedown_rate' => l.evTakedownRate(a),
    'clinch' => l.evClinch(a),
    'separe' => l.evSepare(a),
    'releve' => l.evReleve(a),
    'controle' => l.evControle(a),
    'soumission_tentee' => l.evSoumissionTentee(a),
    'soumission_echappee' => l.evSoumissionEchappee(a),
    'soumission_reussie' => l.evSoumissionReussie(b),
    'signature' => l.evSignature(a),
    'fatigue' => l.evFatigue(a),
    'tactique' => () {
      final k = TacticKind.fromKey(e.detail);
      return k == null ? null : l.evTactique(a, tacticName(l, k));
    }(),
    'fin_round' => l.evFinRound(e.value ?? 0),
    'ko' => l.evKo(a),
    'tko' => l.evTko(a),
    'fin_soumission' => l.evFinSoumission(a),
    'decision' => l.evDecision,
    _ => null,
  };
}
