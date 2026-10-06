import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models.dart';

/// Choix de l'action : cartes en éventail ou roue (même main).
enum ControlMode { cartes, roue }

/// Derniers réglages de combat (retenus d'un combat à l'autre) et minuteur.
@immutable
class CombatPrefs {
  const CombatPrefs({
    this.timer = false,
    this.control = ControlMode.cartes,
    this.level = AiLevel.normal,
    this.format = CombatFormat.court,
    this.openWeight = false,
  });

  /// 15 s pour choisir chaque action (sinon Garde). Désactivé par défaut.
  final bool timer;
  final ControlMode control;
  final AiLevel level;
  final CombatFormat format;
  final bool openWeight;

  CombatPrefs copyWith({bool? timer, ControlMode? control, AiLevel? level, CombatFormat? format, bool? openWeight}) =>
      CombatPrefs(
        timer: timer ?? this.timer,
        control: control ?? this.control,
        level: level ?? this.level,
        format: format ?? this.format,
        openWeight: openWeight ?? this.openWeight,
      );

  Map<String, dynamic> toJson() => {
    'minuteur': timer,
    'commandes': control.name,
    'niveau': level.name,
    'format': format.name,
    'poids_libre': openWeight,
  };

  static CombatPrefs fromJson(Map<String, dynamic> j) => CombatPrefs(
    timer: j['minuteur'] == true,
    control: ControlMode.values.firstWhere((c) => c.name == j['commandes'], orElse: () => ControlMode.cartes),
    level: AiLevel.fromName(j['niveau'] as String?),
    format: CombatFormat.values.firstWhere((f) => f.name == j['format'], orElse: () => CombatFormat.court),
    openWeight: j['poids_libre'] == true,
  );
}

class CombatPrefsNotifier extends Notifier<CombatPrefs> {
  static const _key = 'combat_reglages';

  @override
  CombatPrefs build() {
    _load();
    return const CombatPrefs();
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) state = CombatPrefs.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {}
  }

  Future<void> update(CombatPrefs Function(CombatPrefs) f) async {
    state = f(state);
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final combatPrefsProvider = NotifierProvider<CombatPrefsNotifier, CombatPrefs>(CombatPrefsNotifier.new);

/// Habitudes du joueur apprises par l'IA difficile, gardées sur l'appareil.
class HabitStore {
  static const _key = 'combat_habitudes';

  static Future<HabitProfile> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) return HabitProfile.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {}
    return HabitProfile();
  }

  static Future<void> save(HabitProfile h) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(h.toJson()));
    } catch (_) {}
  }
}

/// Un combattant qui entre dans la cage : sa fiche et la carte jouée.
@immutable
class Contender {
  const Contender({required this.fighter, required this.rarity, required this.bonus, this.owned});

  final Fighter fighter;
  final Rarity rarity;

  /// Bonus de stats de la carte (variante).
  final int bonus;

  /// Exemplaire possédé (pour le joueur).
  final OwnedCard? owned;

  String? get technique => (fighter.ufc['technique_favorite'] as Map?)?['technique'] as String?;

  CombatFighter toCombat() => CombatFighter(
    id: fighter.id,
    name: fighter.nom,
    baseStats: fighter.stats,
    weightClass: fighter.categorie,
    rarity: rarity,
    statBonus: bonus,
    signatureTechnique: technique,
    feminine: fighter.sexe == 'F' || (fighter.categorie?.feminine ?? false),
  );

  int get overall => fighter.stats.withBonus(bonus).overall;
}

/// Tout ce qui est choisi avant le combat.
@immutable
class CombatSetup {
  const CombatSetup({
    required this.player,
    required this.opponent,
    required this.level,
    required this.format,
    required this.seed,
    this.openWeight = false,
    this.titleFight = false,
    this.tactics = const [],
    this.control = ControlMode.cartes,
    this.timer = false,
    this.modeLabel,
    this.allowRematch = true,
  });

  final Contender player;
  final Contender opponent;
  final AiLevel level;
  final CombatFormat format;
  final bool openWeight;
  final bool titleFight;
  final List<TacticCard> tactics;
  final ControlMode control;
  final bool timer;
  final int seed;

  /// Mode de jeu affiché dans l'arène (« Soirée · combat 2/5 »…), null en combat rapide.
  final String? modeLabel;

  /// Revanche proposée à la fin (combat rapide) ; sinon « Continuer » rend le résultat au mode.
  final bool allowRematch;

  CombatConfig get config => CombatConfig(seed: seed, format: format, titleFight: titleFight, openWeight: openWeight);

  /// Même combat, nouvelle graine (revanche).
  CombatSetup rematch() => CombatSetup(
    player: player,
    opponent: opponent,
    level: level,
    format: format,
    seed: newSeed(),
    openWeight: openWeight,
    titleFight: titleFight,
    tactics: tactics,
    control: control,
    timer: timer,
    modeLabel: modeLabel,
    allowRematch: allowRematch,
  );

  static int newSeed() => math.Random.secure().nextInt(1 << 32);
}

/// Adversaires possibles : même genre, même catégorie (sauf poids libre),
/// pas le combattant lui-même, avec des stats de jeu.
List<Fighter> eligibleOpponents(List<Fighter> all, Fighter player, {required bool openWeight}) {
  final fem = player.sexe == 'F' || (player.categorie?.feminine ?? false);
  return [
    for (final f in all)
      if (f.id != player.id &&
          f.categorie != null &&
          f.categorie!.feminine == fem &&
          (openWeight || f.categorie == player.categorie))
        f,
  ];
}

/// Adversaire tiré au hasard, de préférence d'un niveau proche (note globale
/// à 8 points au plus).
Fighter? randomOpponent(List<Fighter> pool, Fighter player, math.Random rng) {
  if (pool.isEmpty) return null;
  final base = player.stats.overall;
  final close = pool.where((f) => (f.stats.overall - base).abs() <= 8).toList();
  final from = close.isNotEmpty ? close : pool;
  return from[rng.nextInt(from.length)];
}

/// Déroulé d'un combat dans l'app : moteur + IA (game_core), journal des
/// événements pour l'affichage.
class CombatController extends ChangeNotifier {
  CombatController(this.setup, {HabitProfile? habits})
    : driver = CombatDriver(
        setup.config,
        setup.player.toCombat(),
        setup.opponent.toCombat(),
        level: setup.level,
        habits: habits,
      ) {
    _absorb();
  }

  final CombatSetup setup;
  final CombatDriver driver;

  /// Tous les événements depuis le début.
  final List<CombatEvent> feed = [];

  /// Événements du dernier coup joué (échange, carte Tactique, mini-jeu).
  List<CombatEvent> lastEvents = const [];

  /// Actions du dernier échange (joueur, IA) et compteur d'échanges joués.
  CombatAction? lastPlayer;
  CombatAction? lastAi;
  int serial = 0;

  /// Abandon du joueur.
  bool gaveUp = false;

  CombatEngine get engine => driver.engine;
  bool get finished => driver.finished || gaveUp;
  CombatResult? get result => driver.result;
  PendingSubmission? get pending => driver.pending;
  List<CombatAction> get options => engine.available(0);

  /// Cartes affichées : la main (4 cartes, doublons compris), la Garde et le
  /// coup signature quand il est prêt.
  List<CombatAction> get hand => [
    ...engine.hand(0),
    CombatAction.garde,
    if (engine.signatureReady(0)) CombatAction.signature,
  ];
  List<String> get names => [setup.player.fighter.nom, setup.opponent.fighter.nom];

  /// Le joueur a gagné (null : match nul ou combat en cours).
  bool? get playerWon {
    if (gaveUp) return false;
    final w = result?.winner;
    return w == null ? null : w == 0;
  }

  bool canUse(TacticCard c) => !finished && engine.canUseTactic(0, c.kind);

  void useTactic(TacticCard c) {
    driver.useTactic(c);
    _absorb();
    notifyListeners();
  }

  void play(CombatAction a) {
    lastPlayer = a;
    lastAi = driver.play(a);
    serial++;
    _absorb();
    notifyListeners();
  }

  void resolveSubmission(double playerSkill) {
    driver.resolveSubmission(playerSkill);
    _absorb();
    notifyListeners();
  }

  void giveUp() {
    gaveUp = true;
    notifyListeners();
  }

  void _absorb() {
    lastEvents = driver.takeEvents();
    feed.addAll(lastEvents);
  }
}
