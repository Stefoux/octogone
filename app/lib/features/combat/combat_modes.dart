import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models.dart';

/// Résultat d'un combat, renvoyé par l'arène au mode qui l'a lancé.
@immutable
class CombatOutcome {
  const CombatOutcome({required this.won, this.method, this.round = 0, this.gaveUp = false});

  /// true : victoire, false : défaite (ou abandon), null : match nul.
  final bool? won;
  final FinishMethod? method;
  final int round;
  final bool gaveUp;

  Map<String, dynamic> toJson() => {'gagne': won, 'methode': method?.name, 'round': round, 'abandon': gaveUp};

  static CombatOutcome fromJson(Map<String, dynamic> j) => CombatOutcome(
    won: j['gagne'] as bool?,
    method: j['methode'] == null ? null : FinishMethod.values.byName(j['methode'] as String),
    round: (j['round'] as num?)?.toInt() ?? 0,
    gaveUp: j['abandon'] == true,
  );
}

/// Classement officiel d'un combattant (ufc.com/rankings, voir
/// data/scripts/fetch_rankings.py) : catégorie et rang (0 = champion).
({WeightClass categorie, int rang, String? date})? rankingOf(Fighter f) {
  final c = f.ufc['classement'];
  if (c is! Map) return null;
  final w = WeightClass.fromKey(c['categorie'] as String?);
  final r = (c['rang'] as num?)?.toInt();
  if (w == null || r == null) return null;
  return (categorie: w, rang: r, date: c['date'] as String?);
}

/// Un échelon de la Route vers la ceinture.
@immutable
class RouteRung {
  const RouteRung({required this.fighter, required this.rank, required this.rarity, this.title = false});
  final Fighter fighter;

  /// Rang officiel de l'adversaire (0 = champion).
  final int rank;
  final Rarity rarity;

  /// Combat pour le titre (5 rounds).
  final bool title;
}

/// Rangs visés, du premier combat au combat pour le titre.
const routeTargets = [15, 10, 5, 3, 1, 0];

/// Écart de rareté de l'adversaire avec la carte du joueur, échelon par échelon.
const _routeRarityOffsets = [-1, -1, 0, 0, 1, 1];

/// Échelle de la Route : les vrais classés de la catégorie du combattant
/// (n°15, n°10, n°5, n°3, n°1, puis le champion), jamais le combattant
/// lui-même ; s'il est champion, le dernier combat est une défense du titre.
/// Vide si la catégorie n'a pas de classement officiel.
List<RouteRung> buildRoute(List<Fighter> all, Fighter player, Rarity rarity) {
  final cat = player.categorie;
  if (cat == null) return const [];
  final ranked = <int, Fighter>{};
  for (final f in all) {
    final r = rankingOf(f);
    if (r != null && r.categorie == cat && f.id != player.id) ranked.putIfAbsent(r.rang, () => f);
  }
  if (ranked.length < routeTargets.length) return const [];
  final used = <int>{};
  final rungs = <RouteRung>[];
  for (var i = 0; i < routeTargets.length; i++) {
    final t = routeTargets[i];
    final last = i == routeTargets.length - 1;
    final ranks = ranked.keys.where((r) => !used.contains(r)).toList()
      ..sort((a, b) {
        final d = (a - t).abs().compareTo((b - t).abs());
        if (d != 0) return d;
        return last ? a.compareTo(b) : b.compareTo(a); // à égalité : plus faible au début, plus fort à la fin
      });
    final r = ranks.first;
    used.add(r);
    final idx = (rarity.index + _routeRarityOffsets[i]).clamp(0, Rarity.values.length - 1);
    rungs.add(RouteRung(fighter: ranked[r]!, rank: r, rarity: Rarity.values[idx], title: last));
  }
  return rungs;
}

/// État d'un mode sauvegardé sur l'appareil (JSON dans les préférences).
class ModeStore {
  static Future<Map<String, dynamic>?> load(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      return raw == null ? null : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String key, Map<String, dynamic>? value) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (value == null) {
        await p.remove(key);
      } else {
        await p.setString(key, jsonEncode(value));
      }
    } catch (_) {}
  }
}

/// Soirée : 5 de mes cartes, un adversaire de sa catégorie pour chacune ; le
/// 5e combat est le main event (5 rounds).
@immutable
class SoireeState {
  const SoireeState({required this.owned, required this.opponents, this.results = const []});

  static const key = 'combat_soiree';
  static const bouts = 5;

  /// Exemplaires joués (owned_cards.id) et adversaires (fighters.id), combat par combat.
  final List<String> owned;
  final List<String> opponents;
  final List<CombatOutcome> results;

  int get next => results.length;
  bool get done => results.length >= bouts;
  int get wins => results.where((r) => r.won == true).length;

  SoireeState record(CombatOutcome o) => SoireeState(owned: owned, opponents: opponents, results: [...results, o]);

  Map<String, dynamic> toJson() => {
    'cartes': owned,
    'adversaires': opponents,
    'resultats': [for (final r in results) r.toJson()],
  };

  static SoireeState? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return SoireeState(
      owned: [for (final e in j['cartes'] as List) e as String],
      opponents: [for (final e in j['adversaires'] as List) e as String],
      results: [for (final e in (j['resultats'] as List? ?? const [])) CombatOutcome.fromJson((e as Map).cast())],
    );
  }
}

/// Route vers la ceinture en cours : la carte jouée, l'échelle (adversaires
/// et raretés) et l'échelon atteint. Une défaite renvoie au début.
@immutable
class RouteState {
  const RouteState({
    required this.owned,
    required this.ladder,
    required this.rarities,
    required this.level,
    required this.format,
    this.step = 0,
    this.lastLost = false,
  });

  static const key = 'combat_route';

  final String owned;
  final List<String> ladder;
  final List<Rarity> rarities;
  final AiLevel level;
  final CombatFormat format;
  final int step;

  /// La dernière tentative s'est soldée par une défaite (retour au début).
  final bool lastLost;

  bool get champion => step >= ladder.length;

  RouteState after(CombatOutcome o) => RouteState(
    owned: owned,
    ladder: ladder,
    rarities: rarities,
    level: level,
    format: format,
    step: o.won == true ? step + 1 : 0,
    lastLost: o.won != true,
  );

  Map<String, dynamic> toJson() => {
    'carte': owned,
    'echelle': ladder,
    'raretes': [for (final r in rarities) r.key],
    'niveau': level.name,
    'format': format.name,
    'echelon': step,
    'defaite': lastLost,
  };

  static RouteState? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return RouteState(
      owned: j['carte'] as String,
      ladder: [for (final e in j['echelle'] as List) e as String],
      rarities: [for (final e in j['raretes'] as List) Rarity.fromKey(e as String)],
      level: AiLevel.fromName(j['niveau'] as String?),
      format: CombatFormat.values.firstWhere((f) => f.name == j['format'], orElse: () => CombatFormat.court),
      step: (j['echelon'] as num?)?.toInt() ?? 0,
      lastLost: j['defaite'] == true,
    );
  }
}

/// Rivalités gagnées : {rivalité : combattants avec lesquels je l'ai gagnée}.
class RivalryProgress extends Notifier<Map<String, Set<String>>> {
  static const _key = 'combat_rivalites';

  @override
  Map<String, Set<String>> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final j = await ModeStore.load(_key);
    if (j == null) return;
    state = {
      for (final e in j.entries) e.key: {for (final f in e.value as List) f as String},
    };
  }

  Future<void> won(String rivalry, String fighter) async {
    state = {
      ...state,
      rivalry: {...?state[rivalry], fighter},
    };
    await ModeStore.save(_key, {for (final e in state.entries) e.key: e.value.toList()});
  }
}

final rivalryProgressProvider = NotifierProvider<RivalryProgress, Map<String, Set<String>>>(RivalryProgress.new);
