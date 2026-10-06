import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../core/l10n.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';

/// Tout ce qu'il faut pour dessiner une carte : définition (checklist),
/// variante (parallèle réel ou rareté originale), combattant(s), et
/// éventuellement l'exemplaire possédé (numéro de série).
class CardView {
  CardView({
    required this.variant,
    required this.fighters,
    this.card,
    this.edition,
    this.series,
    this.owned,
    this.event,
    this.rivalry,
    this.seriesTotal,
    this.ownedCount = 0,
  });

  final Variant variant;
  final List<Fighter> fighters;
  final CardDef? card;
  final Edition? edition;
  final CardSeries? series;
  final OwnedCard? owned;
  final EventInfo? event;
  final Rivalry? rivalry;

  /// Nombre de cartes de la série (pour afficher « 45/200 »).
  final int? seriesTotal;

  /// Exemplaires possédés de cette carte (toutes variantes confondues).
  final int ownedCount;

  Fighter? get fighter => fighters.firstOrNull;

  /// Carte Tactique jouée en combat (null pour une carte de combattant).
  TacticCard? get tactic {
    final k = card?.tactique;
    return k == null ? null : TacticCard(k, rarity, ownedId: owned?.id);
  }

  String get effect => variant.effet;
  Rarity get rarity => Rarity.fromKey(variant.rarete);
  bool get isDuel => fighters.length >= 2;
  bool get isAutograph => series?.type == 'autographe';
  bool get isRookie => card?.isRookie ?? false;
  int? get serial => owned?.numeroSerie;
  int? get printRun => owned?.tirage ?? variant.tirage ?? series?.tirage;

  /// Famille de cadre : celle de l'édition (chrome, papier, original).
  String get frameFamily => edition?.familleCadre ?? 'original';

  /// Note globale avec le bonus de rareté.
  int? get overall {
    final f = fighter;
    if (f == null) return null;
    return f.stats.withBonus(variant.bonusStats).overall;
  }

  /// « 45/200 » pour une numérotation simple, sinon le code tel quel (« AKA-11 »).
  String? get numberLabel {
    final n = card?.numero;
    if (n == null) return null;
    if (int.tryParse(n) != null && seriesTotal != null) return '$n/$seriesTotal';
    return n;
  }
}

/// Nom court d'une carte : combattant, effet Tactique (traduit) ou nom imprimé.
String cardTitle(AppLocalizations l, CardView v) {
  final t = v.tactic;
  return v.fighter?.nom ?? (t != null ? tacticName(l, t.kind) : v.card?.nomImprime) ?? '';
}

/// Variante de base d'une série (« `<series_id>:base` »).
String baseVariantId(String seriesId) => '$seriesId:base';

/// Construit la vue d'une carte depuis le cache local. Renvoie null tant que
/// le contenu n'est pas synchronisé.
CardView? buildCardView(
  WidgetRef ref, {
  required String cardId,
  String? variantId,
  OwnedCard? owned,
}) {
  final cards = ref.watch(allCardsProvider).value;
  final variants = ref.watch(allVariantsProvider).value;
  final series = ref.watch(allSeriesProvider).value;
  if (cards == null || variants == null || series == null) return null;
  final card = cards[cardId];
  if (card == null) return null;
  final variant = variants[owned?.variantId ?? variantId ?? baseVariantId(card.seriesId)] ??
      variants[baseVariantId(card.seriesId)];
  if (variant == null) return null;
  final fightersById = ref.watch(fightersByIdProvider);
  final s = series[card.seriesId];
  final owners = ref.watch(ownedByCardProvider)[cardId] ?? const [];
  final fighters = [for (final id in card.fighterIds) ?fightersById[id]];
  Rivalry? rivalry;
  if (fighters.length >= 2) {
    final key = ([fighters[0].id, fighters[1].id]..sort()).join('--');
    rivalry = ref.watch(rivalriesProvider).value?.firstWhereOrNull((r) => r.id == key);
  }
  return CardView(
    card: card,
    variant: variant,
    fighters: fighters,
    edition: ref.watch(editionsByIdProvider)[card.editionId],
    series: s,
    owned: owned,
    event: card.eventId == null ? null : ref.watch(eventsProvider).value?[card.eventId],
    rivalry: rivalry,
    seriesTotal: s?.nbCartes,
    ownedCount: owners.length,
  );
}
