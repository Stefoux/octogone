/// Niveaux de rareté du jeu, du plus courant au plus rare.
enum Rarity {
  commune,
  peuCommune,
  rare,
  epique,
  legendaire,
  mythique;

  /// Clé stockée en base (`variants.rarete`).
  String get key => switch (this) {
        Rarity.peuCommune => 'peu_commune',
        _ => name,
      };

  static Rarity fromKey(String? key) => switch (key) {
        'peu_commune' => Rarity.peuCommune,
        'rare' => Rarity.rare,
        'epique' => Rarity.epique,
        'legendaire' => Rarity.legendaire,
        'mythique' => Rarity.mythique,
        _ => Rarity.commune,
      };

  /// Le coup signature se débloque à partir d'épique.
  bool get unlocksSignature => index >= Rarity.epique.index;

  /// Bonus de stats par défaut (+1 peu commune … +6 mythique).
  int get defaultStatBonus => const [0, 1, 2, 3, 5, 6][index];
}

/// Règles d'attribution des raretés originales (`variants.eligibilite`).
///
/// Clés possibles (toutes facultatives, combinées en ET) :
///   champion: true          champion UFC actuel ou ancien (Ceinture d'Or)
///   legende_retraitee: true retraité ET (ancien champion OU 10 victoires UFC ou plus) (Héritage)
///   fotn_min: n             au moins n bonus « Combat de la soirée » (Cicatrice : les guerres)
///   ko_min: n               au moins n victoires par KO/TKO en carrière (Onde de Choc)
///   sub_min: n              au moins n victoires par soumission (Clé Fatale)
///   carte: duel|evenement|celebration   type de carte requis (Face-à-Face, Moment, Main Levée…)
///   combats_min: n          (cartes duel) au moins n combats entre les deux rivaux (Trilogie)
class Eligibility {
  static bool isEligible(
    Map<String, dynamic>? rule,
    Map<String, dynamic> fighter, {
    String cardType = 'simple',
    int fightsBetween = 0,
  }) {
    if (rule == null || rule.isEmpty) return cardType == 'simple';
    final requiredType = rule['carte'] as String?;
    if ((requiredType ?? 'simple') != cardType) return false;

    final palmares = (fighter['palmares'] as Map?)?.cast<String, dynamic>() ?? const {};
    final ufc = (fighter['ufc'] as Map?)?.cast<String, dynamic>() ?? const {};
    int n(Object? v) => v is num ? v.toInt() : 0;

    if (rule['champion'] == true &&
        !(fighter['champion_actuel'] == true || fighter['ancien_champion'] == true)) {
      return false;
    }
    if (rule['legende_retraitee'] == true) {
      final retired = fighter['statut'] == 'retraite';
      final legend = fighter['ancien_champion'] == true || n(ufc['victoires_ufc']) >= 10;
      if (!(retired && legend)) return false;
    }
    if (rule['fotn_min'] != null && n(ufc['bonus_fotn']) < n(rule['fotn_min'])) return false;
    if (rule['ko_min'] != null && n(palmares['victoires_ko']) < n(rule['ko_min'])) return false;
    if (rule['sub_min'] != null && n(palmares['victoires_soumission']) < n(rule['sub_min'])) return false;
    if (rule['combats_min'] != null && fightsBetween < n(rule['combats_min'])) return false;
    return true;
  }
}
