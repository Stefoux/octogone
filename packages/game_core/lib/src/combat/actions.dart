/// Positions et actions du combat.
library;

/// Position du combat. Au sol, [CombatState.top] indique qui est dessus.
enum Position { debout, clinch, sol }

/// Famille d'une action (sert à la résolution, à l'IA et aux juges).
enum ActionKind { frappe, lutte, soumission, controle, degagement, defense, signature }

/// Actions jouables. [cost] : endurance dépensée (négatif = récupération).
/// [base] : chance de réussite de base ; [damage] : dégâts de base (sur 100 PV).
enum CombatAction {
  frappeRapide('frappe_rapide', ActionKind.frappe, cost: 4, base: 0.62, damage: 9),
  frappePuissante('frappe_puissante', ActionKind.frappe, cost: 9, base: 0.45, damage: 21, heavy: true),
  coupDePied('coup_de_pied', ActionKind.frappe, cost: 7, base: 0.52, damage: 14, heavy: true),
  takedown('takedown', ActionKind.lutte, cost: 10, base: 0.42),
  clinch('clinch', ActionKind.lutte, cost: 5, base: 0.55),
  garde('garde', ActionKind.defense, cost: -3, base: 1),
  esquive('esquive', ActionKind.defense, cost: 3, base: 1),
  groundAndPound('ground_and_pound', ActionKind.frappe, cost: 8, base: 0.58, damage: 15, heavy: true),
  soumission('soumission', ActionKind.soumission, cost: 9, base: 0.38),
  seRelever('se_relever', ActionKind.degagement, cost: 6, base: 0.45),
  controle('controle', ActionKind.controle, cost: 3, base: 0.72),
  signature('signature', ActionKind.signature, cost: 0, base: 0.72, damage: 28, heavy: true);

  const CombatAction(this.key, this.kind,
      {required this.cost, required this.base, this.damage = 0, this.heavy = false});

  final String key;
  final ActionKind kind;
  final int cost;
  final double base;
  final int damage;

  /// Coup appuyé : peut provoquer un knockdown ou un KO.
  final bool heavy;

  bool get offensive => kind != ActionKind.defense;

  static CombatAction fromKey(String key) => values.firstWhere((a) => a.key == key);
}

/// Situation d'un combattant, qui détermine les actions possibles et la main
/// de cartes utilisée.
enum Stance { debout, clinch, dessus, dessous }

/// Actions possibles dans chaque situation (hors Garde, toujours possible, et
/// hors coup signature, ajouté quand le momentum est plein).
const Map<Stance, List<CombatAction>> stanceActions = {
  Stance.debout: [
    CombatAction.frappeRapide,
    CombatAction.frappePuissante,
    CombatAction.coupDePied,
    CombatAction.takedown,
    CombatAction.clinch,
    CombatAction.esquive,
  ],
  Stance.clinch: [
    CombatAction.frappeRapide,
    CombatAction.frappePuissante, // genou
    CombatAction.takedown,
    CombatAction.seRelever, // se dégager
    CombatAction.controle, // contre la cage
  ],
  Stance.dessus: [
    CombatAction.groundAndPound,
    CombatAction.soumission,
    CombatAction.controle,
    CombatAction.seRelever, // se relever volontairement
  ],
  Stance.dessous: [
    CombatAction.soumission, // depuis la garde
    CombatAction.seRelever,
  ],
};

/// Modificateur de réussite de l'action [a] face à l'action adverse [b]
/// (le « pierre-feuille-ciseaux » du combat : le Contre punit la Frappe
/// puissante, le Takedown passe sous la Frappe puissante, la Frappe rapide
/// sanctionne un Takedown mal préparé…).
double matchup(CombatAction a, CombatAction b, Stance stance) {
  final m = switch (stance) {
    Stance.debout => _standing,
    Stance.clinch => _clinch,
    Stance.dessus || Stance.dessous => _ground,
  };
  return m[a]?[b] ?? 0;
}

const _standing = <CombatAction, Map<CombatAction, double>>{
  CombatAction.frappeRapide: {
    CombatAction.frappePuissante: 0.08,
    CombatAction.coupDePied: 0.05,
    CombatAction.takedown: 0.15,
    CombatAction.garde: -0.25,
    CombatAction.esquive: -0.30,
  },
  CombatAction.frappePuissante: {
    CombatAction.frappeRapide: -0.05,
    CombatAction.takedown: -0.10,
    CombatAction.clinch: -0.10,
    CombatAction.garde: -0.30,
    CombatAction.esquive: -0.35,
  },
  CombatAction.coupDePied: {
    CombatAction.frappeRapide: -0.05,
    CombatAction.frappePuissante: 0.05,
    CombatAction.takedown: -0.15,
    CombatAction.clinch: -0.10,
    CombatAction.garde: -0.20,
    CombatAction.esquive: -0.25,
  },
  CombatAction.takedown: {
    CombatAction.frappeRapide: -0.20,
    CombatAction.frappePuissante: 0.25,
    CombatAction.coupDePied: 0.20,
    CombatAction.clinch: 0.10,
    CombatAction.garde: -0.05,
    CombatAction.esquive: -0.10,
  },
  CombatAction.clinch: {
    CombatAction.frappePuissante: 0.15,
    CombatAction.coupDePied: 0.10,
    CombatAction.takedown: -0.05,
    CombatAction.clinch: 0.10,
    CombatAction.garde: 0.05,
    CombatAction.esquive: -0.15,
  },
  CombatAction.signature: {
    CombatAction.garde: -0.15,
    CombatAction.esquive: -0.20,
  },
};

const _clinch = <CombatAction, Map<CombatAction, double>>{
  CombatAction.frappeRapide: {
    CombatAction.garde: -0.20,
    CombatAction.takedown: 0.10,
    CombatAction.seRelever: -0.10,
  },
  CombatAction.frappePuissante: {
    CombatAction.garde: -0.25,
    CombatAction.takedown: 0.10,
    CombatAction.controle: 0.05,
  },
  CombatAction.takedown: {
    CombatAction.seRelever: -0.15,
    CombatAction.controle: -0.10,
    CombatAction.frappePuissante: 0.10,
    CombatAction.garde: 0.05,
  },
  CombatAction.seRelever: {
    CombatAction.controle: -0.25,
    CombatAction.takedown: -0.10,
    CombatAction.frappePuissante: 0.05,
    CombatAction.garde: 0.10,
  },
  CombatAction.controle: {
    CombatAction.seRelever: 0.05,
    CombatAction.frappeRapide: 0.05,
  },
};

const _ground = <CombatAction, Map<CombatAction, double>>{
  CombatAction.groundAndPound: {
    CombatAction.garde: -0.20,
    CombatAction.seRelever: 0.05,
    CombatAction.soumission: 0.05,
  },
  CombatAction.soumission: {
    CombatAction.garde: -0.15,
    CombatAction.seRelever: -0.10,
    CombatAction.groundAndPound: 0.10,
    CombatAction.controle: -0.15,
  },
  CombatAction.seRelever: {
    CombatAction.groundAndPound: 0.05,
    CombatAction.controle: -0.30,
    CombatAction.soumission: 0.10,
    CombatAction.garde: 0.15,
  },
  CombatAction.controle: {
    CombatAction.seRelever: 0.05,
    CombatAction.soumission: 0.05,
  },
  CombatAction.signature: {
    CombatAction.garde: -0.10,
  },
};
