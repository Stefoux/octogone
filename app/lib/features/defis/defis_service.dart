import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/content_providers.dart';
import '../boosters/booster_service.dart';

/// Défi en cours (quotidien ou hebdomadaire) et sa progression.
class Defi {
  Defi(Map<String, dynamic> j)
      : id = j['modele_id'] as String,
        periode = j['periode'] as String,
        type = j['type'] as String,
        objectif = (j['objectif'] as num).toInt(),
        pieces = (j['pieces'] as num).toInt(),
        libelle = ((j['libelle'] as Map?) ?? const {}).cast<String, dynamic>(),
        progression = (j['progression'] as num).toInt(),
        recupere = j['recupere'] == true,
        fin = DateTime.parse(j['fin'] as String).toLocal();

  final String id;
  final String periode;
  final String type;
  final int objectif;
  final int pieces;
  final Map<String, dynamic> libelle;
  final int progression;
  final bool recupere;
  final DateTime fin;

  bool get daily => periode == 'jour';
  bool get done => progression >= objectif;
  bool get claimable => done && !recupere;

  String title(String lang) => (libelle[lang] ?? libelle['fr'] ?? id) as String;
}

enum DefiError { alreadyClaimed, notDone, other }

class DefiException implements Exception {
  DefiException(this.kind, [this.message]);
  final DefiError kind;
  final String? message;
}

abstract class DefisService {
  Future<List<Defi>> load();

  /// Récupère la récompense ; renvoie le nouveau solde de pièces.
  Future<int> claim(String id);
}

class SupabaseDefisService implements DefisService {
  SupabaseDefisService(this.ref);
  final Ref ref;

  @override
  Future<List<Defi>> load() async {
    final rows = await ref.read(supabaseProvider).rpc<List<dynamic>>('mes_defis');
    return [for (final r in rows) Defi((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<int> claim(String id) async {
    try {
      final pieces = await ref.read(supabaseProvider).rpc<int>('recuperer_defi', params: {'p_modele': id});
      ref.invalidate(walletProvider);
      return pieces;
    } on PostgrestException catch (e) {
      throw DefiException(
        switch (e.code) {
          'P0012' => DefiError.alreadyClaimed,
          'P0013' => DefiError.notDone,
          _ => DefiError.other,
        },
        e.message,
      );
    }
  }
}

final defisServiceProvider = Provider<DefisService>(SupabaseDefisService.new);

final defisProvider = FutureProvider<List<Defi>>((ref) => ref.watch(defisServiceProvider).load());

/// Nombre de récompenses à récupérer (pastille de l'accueil).
final defisClaimableProvider = Provider<int>(
  (ref) => (ref.watch(defisProvider).value ?? const <Defi>[]).where((d) => d.claimable).length,
);
