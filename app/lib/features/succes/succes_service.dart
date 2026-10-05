import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/content_providers.dart';
import '../boosters/booster_service.dart';
import '../defis/defis_service.dart' show DefiError, DefiException;

/// Succès permanent et sa progression (calculée par le serveur).
class Succes {
  Succes(Map<String, dynamic> j)
      : id = j['succes_id'] as String,
        type = j['type'] as String,
        objectif = (j['objectif'] as num).toInt(),
        pieces = (j['pieces'] as num).toInt(),
        libelle = ((j['libelle'] as Map?) ?? const {}).cast<String, dynamic>(),
        progression = (j['progression'] as num).toInt(),
        recupere = j['recupere'] == true;

  final String id;
  final String type;
  final int objectif;
  final int pieces;
  final Map<String, dynamic> libelle;
  final int progression;
  final bool recupere;

  bool get done => progression >= objectif;
  bool get claimable => done && !recupere;

  String title(String lang) => (libelle[lang] ?? libelle['fr'] ?? id) as String;
}

abstract class SuccesService {
  Future<List<Succes>> load();

  /// Récupère la récompense ; renvoie le nouveau solde de pièces.
  Future<int> claim(String id);
}

class SupabaseSuccesService implements SuccesService {
  SupabaseSuccesService(this.ref);
  final Ref ref;

  @override
  Future<List<Succes>> load() async {
    final rows = await ref.read(supabaseProvider).rpc<List<dynamic>>('mes_succes');
    return [for (final r in rows) Succes((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<int> claim(String id) async {
    try {
      final pieces = await ref.read(supabaseProvider).rpc<int>('recuperer_succes', params: {'p_id': id});
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

final succesServiceProvider = Provider<SuccesService>(SupabaseSuccesService.new);

final succesProvider = FutureProvider<List<Succes>>((ref) => ref.watch(succesServiceProvider).load());
