import '../cards/rarity.dart';
import '../model/weight_class.dart';
import '../stats/stat_formula.dart';
import 'actions.dart';
import 'rng.dart';

/// Coup signature : un KO (frappe) ou une soumission, selon la technique de
/// finition la plus marquante du combattant (données réelles).
enum SignatureKind { frappe, soumission }

/// Combattant tel qu'il entre dans la cage : stats de jeu avec le bonus de
/// rareté de la carte jouée.
class CombatFighter {
  CombatFighter({
    required this.id,
    required this.name,
    required GameStats baseStats,
    required this.weightClass,
    required this.rarity,
    this.statBonus,
    this.signatureTechnique,
    this.feminine = false,
  }) : stats = baseStats.withBonus(statBonus ?? rarity.defaultStatBonus);

  final String id;
  final String name;

  /// Stats avec le bonus de rareté.
  final GameStats stats;
  final WeightClass? weightClass;
  final Rarity rarity;
  final int? statBonus;
  final String? signatureTechnique;
  final bool feminine;

  FighterStyle get style => stats.style;

  int operator [](StatKind k) => stats[k];

  bool get hasSignature => rarity.unlocksSignature;

  SignatureKind get signatureKind {
    final t = (signatureTechnique ?? '').toLowerCase();
    return RegExp(r'choke|armbar|triangle|guillotine|kimura|lock|submission|étrangl|clé|soumission|bar\b')
            .hasMatch(t)
        ? SignatureKind.soumission
        : SignatureKind.frappe;
  }

  /// Données JSON minimales (fiche combattant + rareté de la carte jouée).
  /// Format : {id, nom, categorie, sexe, stats_jeu, rarete, bonus_stats?,
  /// technique?}.
  factory CombatFighter.fromJson(Map<String, dynamic> j) => CombatFighter(
        id: j['id'] as String,
        name: j['nom'] as String? ?? j['id'] as String,
        baseStats: GameStats.fromJson((j['stats_jeu'] as Map).cast<String, dynamic>()),
        weightClass: WeightClass.fromKey(j['categorie'] as String?),
        rarity: Rarity.fromKey(j['rarete'] as String?),
        statBonus: (j['bonus_stats'] as num?)?.toInt(),
        signatureTechnique: j['technique'] as String?,
        feminine: j['sexe'] == 'F' || ((j['categorie'] as String?)?.endsWith('_f') ?? false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': name,
        'categorie': weightClass?.key,
        'sexe': feminine ? 'F' : 'M',
        'stats_jeu': {for (final k in StatKind.values) k.name: stats[k] - (statBonus ?? rarity.defaultStatBonus)},
        'rarete': rarity.key,
        'bonus_stats': statBonus,
        'technique': signatureTechnique,
      };

  // --- Main de cartes d'action ----------------------------------------------

  /// Poids de tirage des cartes d'action selon le profil : un frappeur
  /// reçoit plus de coups, un lutteur plus de takedowns, un combattant au bon
  /// menton plus de cartes de défense et d'esquive.
  double cardWeight(CombatAction a, Stance stance) {
    double s(StatKind k) => this[k] / 99.0;
    final style = this.style;
    final striker = style == FighterStyle.frappeur ? 1.0 : 0.0;
    final wrestler = style == FighterStyle.lutteur ? 1.0 : 0.0;
    final grappler = style == FighterStyle.grappler ? 1.0 : 0.0;
    // Complet : à l'aise partout, sa main mélange coups et lutte
    final complete = style == FighterStyle.complet ? 0.5 : 0.0;
    final durable = ((this[StatKind.menton] + this[StatKind.defense]) / 2 - 55) / 30;
    switch (stance) {
      case Stance.debout:
        return switch (a) {
          CombatAction.frappeRapide => 1.4 + 1.6 * s(StatKind.frappe) + 0.8 * striker + complete,
          CombatAction.frappePuissante => 0.8 + 1.8 * s(StatKind.puissance) + 0.8 * striker + complete,
          CombatAction.coupDePied => 0.8 + 1.2 * s(StatKind.frappe) + 0.6 * striker,
          CombatAction.takedown => 0.4 + 2.2 * s(StatKind.lutte) + 1.2 * wrestler + 0.6 * grappler + complete,
          CombatAction.clinch => 0.6 + 1.2 * s(StatKind.lutte) + 0.6 * wrestler + 0.4 * grappler,
          CombatAction.esquive => 0.9 + (durable > 0 ? durable : 0) * 1.2,
          _ => 0,
        };
      case Stance.clinch:
        return switch (a) {
          CombatAction.frappeRapide => 1.2 + 1.0 * s(StatKind.frappe),
          CombatAction.frappePuissante => 0.8 + 1.4 * s(StatKind.puissance) + 0.4 * striker,
          CombatAction.takedown => 0.6 + 2.0 * s(StatKind.lutte) + 0.8 * wrestler,
          CombatAction.seRelever => 1.0 + 0.8 * striker,
          CombatAction.controle => 0.6 + 1.4 * s(StatKind.lutte) + 0.6 * wrestler,
          _ => 0,
        };
      case Stance.dessus:
        return switch (a) {
          CombatAction.groundAndPound => 1.0 + 1.6 * s(StatKind.puissance) + 0.6 * wrestler,
          CombatAction.soumission => 0.5 + 2.2 * s(StatKind.soumission) + 1.2 * grappler,
          CombatAction.controle => 0.8 + 1.4 * s(StatKind.lutte) + 0.6 * wrestler,
          CombatAction.seRelever => 0.4 + 0.8 * striker,
          _ => 0,
        };
      case Stance.dessous:
        return switch (a) {
          CombatAction.soumission => 0.6 + 2.0 * s(StatKind.soumission) + 1.0 * grappler,
          CombatAction.seRelever => 1.4 + 1.2 * s(StatKind.lutte) + 0.4 * s(StatKind.cardio),
          _ => 0,
        };
    }
  }

  /// Tire une carte d'action pour la situation donnée.
  CombatAction drawCard(Stance stance, CombatRng rng) {
    final options = stanceActions[stance]!;
    final i = rng.weighted([for (final a in options) cardWeight(a, stance)]);
    return options[i];
  }
}
