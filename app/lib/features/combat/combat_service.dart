import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/content_providers.dart';
import '../boosters/booster_service.dart';
import '../defis/defis_service.dart';
import '../succes/succes_service.dart';
import 'combat_session.dart';

/// Récompense d'un combat après vérification par le serveur.
@immutable
class CombatReward {
  const CombatReward({required this.status, this.coins = 0, this.capped = false});

  /// valide, refuse, attente (hors ligne : envoyé plus tard), horsligne
  /// (combat commencé sans réseau : pas de récompense).
  final String status;
  final int coins;

  /// Plafond quotidien atteint (gain réduit).
  final bool capped;

  static const pending = CombatReward(status: 'attente');
  static const offline = CombatReward(status: 'horsligne');
}

/// Un combat de l'historique (table combats).
@immutable
class CombatRecord {
  CombatRecord(Map<String, dynamic> j)
    : date = DateTime.tryParse(j['cree_le'] as String? ?? ''),
      mode = j['mode'] as String? ?? 'rapide',
      opponent = j['adversaire'] as String,
      status = j['statut'] as String? ?? '',
      winner = (j['vainqueur'] as num?)?.toInt(),
      method = j['methode'] as String?,
      coins = (j['pieces'] as num?)?.toInt() ?? 0;

  final DateTime? date;
  final String mode;
  final String opponent;
  final String status;
  final int? winner;
  final String? method;
  final int coins;
}

/// Combats vérifiés par le serveur : graine tirée au début
/// (commencer_combat), journal rejoué à la fin (Edge Function valider-combat),
/// file d'attente quand le réseau manque.
abstract class CombatService {
  /// Graine et identifiant du combat côté serveur ; null hors ligne.
  Future<({String id, int seed})?> start(CombatSetup setup);

  /// Envoie le journal ; renvoie la récompense (ou « en attente » si l'envoi échoue).
  Future<CombatReward> finish(CombatSetup setup, CombatController c);

  Future<void> abandon(String id);

  /// Renvoie les combats restés en attente.
  Future<void> flush();

  /// Derniers combats terminés (historique du serveur).
  Future<List<CombatRecord>> history({int limit = 10});

  /// Le combat avec sa graine serveur (ou la graine locale hors ligne).
  Future<CombatSetup> prepare(CombatSetup setup) async {
    final s = await start(setup);
    return s == null ? setup : setup.withServer(id: s.id, seed: s.seed);
  }
}

class SupabaseCombatService extends CombatService {
  SupabaseCombatService(this.ref);
  final Ref ref;

  static const _queueKey = 'combat_file';

  SupabaseClient get _client => ref.read(supabaseProvider);

  @override
  Future<({String id, int seed})?> start(CombatSetup setup) async {
    final owned = setup.player.owned;
    if (owned == null) return null;
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'commencer_combat',
        params: {
          'p_mode': setup.mode,
          'p_carte': owned.id,
          'p_adversaire': setup.opponent.fighter.id,
          'p_adversaire_rarete': setup.opponent.rarity.key,
          'p_niveau': setup.level.name,
          'p_format': setup.format.name,
          'p_titre': setup.titleFight,
          'p_poids_libre': setup.openWeight,
        },
      );
      final r = (rows.first as Map).cast<String, dynamic>();
      return (id: r['id'] as String, seed: (r['graine'] as num).toInt());
    } catch (_) {
      return null; // hors ligne : combat pour le plaisir, sans récompense
    }
  }

  Map<String, dynamic> _payload(CombatSetup setup, CombatController c) => {
    'combat_id': setup.combatId,
    'journal': c.engine.log,
    'habitudes': c.habitsSnapshot,
    'tactiques': [for (final t in setup.tactics) t.toJson()],
  };

  Future<CombatReward> _send(Map<String, dynamic> payload) async {
    final res = await _client.functions.invoke('valider-combat', body: payload);
    final data = (res.data as Map).cast<String, dynamic>();
    ref
      ..invalidate(walletProvider)
      ..invalidate(defisProvider)
      ..invalidate(succesProvider)
      ..invalidate(combatHistoryProvider);
    return CombatReward(
      status: data['statut'] as String? ?? 'refuse',
      coins: (data['pieces'] as num?)?.toInt() ?? 0,
      capped: data['plafond'] == true,
    );
  }

  @override
  Future<CombatReward> finish(CombatSetup setup, CombatController c) async {
    if (setup.combatId == null) return CombatReward.offline;
    final payload = _payload(setup, c);
    try {
      final reward = await _send(payload);
      await flush();
      return reward;
    } on FunctionException catch (e) {
      // Refus définitif (combat inconnu, requête invalide) : rien à renvoyer
      if (e.status >= 400 && e.status < 500) return const CombatReward(status: 'refuse');
      await _enqueue(payload);
      return CombatReward.pending;
    } catch (_) {
      await _enqueue(payload);
      return CombatReward.pending;
    }
  }

  @override
  Future<void> abandon(String id) async {
    try {
      await _client.rpc<void>('abandonner_combat', params: {'p_id': id});
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _queue() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_queueKey);
      if (raw == null) return [];
      return [for (final e in jsonDecode(raw) as List) (e as Map).cast<String, dynamic>()];
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> q) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_queueKey, jsonEncode(q));
    } catch (_) {}
  }

  Future<void> _enqueue(Map<String, dynamic> payload) async => _saveQueue([...await _queue(), payload]);

  @override
  Future<List<CombatRecord>> history({int limit = 10}) async {
    try {
      final rows = await _client
          .from('combats')
          .select('cree_le, mode, adversaire, statut, vainqueur, methode, pieces')
          .neq('statut', 'en_cours')
          .order('cree_le', ascending: false)
          .limit(limit);
      return [for (final r in rows) CombatRecord(r)];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> flush() async {
    final q = await _queue();
    if (q.isEmpty) return;
    final left = <Map<String, dynamic>>[];
    for (final p in q) {
      try {
        await _send(p);
      } on FunctionException catch (e) {
        if (e.status >= 500) left.add(p);
      } catch (_) {
        left.add(p);
      }
    }
    await _saveQueue(left);
  }
}

final combatServiceProvider = Provider<CombatService>(SupabaseCombatService.new);

final combatHistoryProvider = FutureProvider<List<CombatRecord>>((ref) => ref.watch(combatServiceProvider).history());
