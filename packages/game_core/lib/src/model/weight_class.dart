/// Catégories de poids UFC. [key] est la valeur stockée en base et dans les
/// JSON de `data/fighters`.
enum WeightClass {
  pailleF('paille_f', 'Poids paille (F)', 52, feminine: true),
  moucheF('mouche_f', 'Poids mouche (F)', 57, feminine: true),
  coqF('coq_f', 'Poids coq (F)', 61, feminine: true),
  plumeF('plume_f', 'Poids plume (F)', 66, feminine: true),
  mouche('mouche', 'Poids mouche', 57),
  coq('coq', 'Poids coq', 61),
  plume('plume', 'Poids plume', 66),
  legers('legers', 'Poids légers', 70),
  miMoyens('mi_moyens', 'Poids mi-moyens', 77),
  moyens('moyens', 'Poids moyens', 84),
  miLourds('mi_lourds', 'Poids mi-lourds', 93),
  lourds('lourds', 'Poids lourds', 120);

  const WeightClass(this.key, this.label, this.limitKg, {this.feminine = false});

  final String key;
  final String label;

  /// Limite de poids en kg (arrondie), utilisée pour le malus inter-catégories.
  final int limitKg;
  final bool feminine;

  static WeightClass? fromKey(String? key) {
    if (key == null) return null;
    for (final w in values) {
      if (w.key == key) return w;
    }
    return null;
  }

  /// Écart en nombre de catégories (même genre) : sert au malus inter-catégories.
  int distanceTo(WeightClass other) {
    final order = feminine == other.feminine
        ? values.where((w) => w.feminine == feminine).toList()
        : values;
    return (order.indexOf(this) - order.indexOf(other)).abs();
  }
}
