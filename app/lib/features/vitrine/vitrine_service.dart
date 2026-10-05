import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/content_providers.dart';

/// Nombre d'emplacements de la vitrine (le premier est la place d'honneur).
const kVitrineSlots = 9;

/// Stockage de la vitrine : liste de [kVitrineSlots] identifiants
/// d'exemplaires possédés (owned_cards.id), null = emplacement vide.
abstract class VitrineStore {
  Future<List<String?>> load();
  Future<void> save(List<String?> slots);
}

/// Vitrine enregistrée sur le serveur (table vitrine_slots, fonction
/// set_vitrine qui vérifie que les cartes t'appartiennent).
class SupabaseVitrineStore implements VitrineStore {
  SupabaseVitrineStore(this.ref);
  final Ref ref;

  @override
  Future<List<String?>> load() async {
    final client = ref.read(supabaseProvider);
    final rows = await client.from('vitrine_slots').select('slot, owned_card_id');
    final slots = List<String?>.filled(kVitrineSlots, null);
    for (final r in rows) {
      final i = (r['slot'] as num).toInt();
      if (i >= 0 && i < kVitrineSlots) slots[i] = r['owned_card_id'] as String;
    }
    return slots;
  }

  @override
  Future<void> save(List<String?> slots) async {
    // Les emplacements vides de fin sont inutiles côté serveur
    var last = slots.lastIndexWhere((s) => s != null);
    await ref.read(supabaseProvider).rpc<void>('set_vitrine', params: {'p_cards': slots.sublist(0, last + 1)});
  }
}

final vitrineStoreProvider = Provider<VitrineStore>(SupabaseVitrineStore.new);

/// Vitrine du joueur. Affichage immédiat depuis le cache de l'appareil, puis
/// mise à jour depuis le serveur ; chaque modification est enregistrée sur le
/// serveur (et annulée si l'enregistrement échoue).
class VitrineController extends AsyncNotifier<List<String?>> {
  static const _cacheKey = 'vitrine_cache';

  @override
  Future<List<String?>> build() async {
    final store = ref.watch(vitrineStoreProvider);
    try {
      final slots = await store.load();
      await _writeCache(slots);
      return slots;
    } catch (_) {
      // Hors ligne : dernière vitrine connue
      return _readCache();
    }
  }

  List<String?> get _current => state.value ?? List<String?>.filled(kVitrineSlots, null);

  bool contains(String ownedId) => _current.contains(ownedId);

  bool get isFull => !_current.contains(null);

  Future<void> _commit(List<String?> next) async {
    final previous = _current;
    state = AsyncData(next);
    try {
      await ref.read(vitrineStoreProvider).save(next);
      await _writeCache(next);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Expose [ownedId] à la place [slot] (par défaut : la première libre,
  /// en commençant par la place d'honneur). Renvoie false si la vitrine est pleine.
  Future<bool> add(String ownedId, {int? slot}) async {
    final next = [..._current];
    if (next.contains(ownedId)) return true;
    final i = slot ?? next.indexOf(null);
    if (i < 0) return false;
    next[i] = ownedId;
    await _commit(next);
    return true;
  }

  Future<void> remove(String ownedId) async {
    final next = [for (final s in _current) s == ownedId ? null : s];
    await _commit(next);
  }

  /// Échange deux emplacements (glisser-déposer).
  Future<void> swap(int a, int b) async {
    if (a == b) return;
    final next = [..._current];
    final t = next[a];
    next[a] = next[b];
    next[b] = t;
    await _commit(next);
  }

  Future<List<String?>> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<String?>();
        if (list.length == kVitrineSlots) return list;
      }
    } catch (_) {}
    return List<String?>.filled(kVitrineSlots, null);
  }

  Future<void> _writeCache(List<String?> slots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(slots));
    } catch (_) {}
  }
}

final vitrineProvider = AsyncNotifierProvider<VitrineController, List<String?>>(VitrineController.new);
