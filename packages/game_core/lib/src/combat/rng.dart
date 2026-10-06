/// Générateur pseudo-aléatoire déterministe (xorshift32).
///
/// Même graine → même suite de nombres, dans l'app (Dart) comme sur le serveur
/// (Dart compilé en JavaScript) : seules des opérations sur 32 bits (décalages,
/// ou exclusif, masque) sont utilisées, qui donnent le même résultat partout.
/// C'est ce qui permet au serveur de rejouer un combat à l'identique.
class CombatRng {
  CombatRng(int seed) : _x = _mix(seed);

  int _x;

  static int _mix(int seed) {
    var x = seed & 0xFFFFFFFF;
    if (x == 0) x = 0x6D2B79F5;
    return x;
  }

  /// Entier 32 bits non signé suivant.
  int nextUint32() {
    var x = _x;
    x = (x ^ ((x << 13) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    x = (x ^ (x >> 17)) & 0xFFFFFFFF;
    x = (x ^ ((x << 5) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    _x = x;
    return x;
  }

  /// Réel dans [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Entier dans [0, max).
  int nextInt(int max) => (nextDouble() * max).floor();

  /// Choix pondéré : renvoie l'indice tiré selon [weights] (poids positifs).
  int weighted(List<double> weights) {
    var total = 0.0;
    for (final w in weights) {
      total += w;
    }
    if (total <= 0) return 0;
    var r = nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      r -= weights[i];
      if (r < 0) return i;
    }
    return weights.length - 1;
  }
}
