import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../cards/card_view.dart';
import '../cards/trading_card.dart';

/// Choisir un de ses exemplaires (vitrine aujourd'hui ; decks et échanges
/// plus tard). Les plus rares d'abord, recherche par nom de combattant.
/// Renvoie null si le joueur ferme sans choisir.
Future<OwnedCard?> pickOwnedCard(
  BuildContext context, {
  required String title,
  Set<String> exclude = const {},
  bool Function(CardView view)? where,
}) {
  return showModalBottomSheet<OwnedCard>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
    builder: (_) => _Picker(title: title, exclude: exclude, where: where),
  );
}

class _Picker extends ConsumerStatefulWidget {
  const _Picker({required this.title, required this.exclude, this.where});
  final String title;
  final Set<String> exclude;

  /// Filtre (ex. combat : cartes d'un seul combattant).
  final bool Function(CardView view)? where;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final owned = ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[];
    final q = _query.trim().toLowerCase();
    final views = <CardView>[
      for (final o in owned)
        if (!widget.exclude.contains(o.id)) ?buildCardView(ref, cardId: o.cardId, owned: o),
    ]
        .where((v) => widget.where?.call(v) ?? true)
        .where((v) => q.isEmpty || v.fighters.any((f) => f.nom.toLowerCase().contains(q)) ||
            (v.card?.nomImprime.toLowerCase().contains(q) ?? false))
        .sorted((a, b) {
      final r = Rarity.fromKey(b.variant.rarete).index.compareTo(Rarity.fromKey(a.variant.rarete).index);
      if (r != 0) return r;
      return (a.fighter?.nom ?? '').compareTo(b.fighter?.nom ?? '');
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(
          key: const Key('picker-search'),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.vitrinePickSearch),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: views.isEmpty
              ? Center(child: Text(l.vitrinePickEmpty, style: const TextStyle(color: AppColors.textMuted)))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: kCardAspect * 0.86,
                  ),
                  itemCount: views.length,
                  itemBuilder: (context, i) {
                    final v = views[i];
                    return InkWell(
                      key: Key('pick-${v.owned!.id}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context, v.owned),
                      child: Column(children: [
                        Expanded(child: TradingCard(view: v, animate: false)),
                        const SizedBox(height: 4),
                        Text(rarityLabel(l, v.variant.rarete),
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.rarity[v.variant.rarete])),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
