import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/rarity_backdrop.dart';
import '../vitrine/vitrine_screen.dart';
import 'card_view.dart';
import 'interactive_card.dart';

/// Vue détaillée d'une carte : retournement, reflets qui suivent le
/// téléphone, zoom à deux doigts. Fonctionne aussi pour une carte non
/// possédée (aperçu).
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId, this.variantId, this.ownedId, this.preview});

  final String cardId;
  final String? variantId;
  final String? ownedId;

  /// Vue toute faite (vitrine des effets) : prioritaire sur cardId.
  final CardView? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final owned = ownedId == null
        ? null
        : ref.watch(ownedCardsProvider).value?.firstWhereOrNull((o) => o.id == ownedId);
    final view = preview ?? buildCardView(ref, cardId: cardId, variantId: variantId, owned: owned);

    // Fond propre à la rareté (la carte elle-même est inchangée)
    return RarityBackdrop(
      rarete: view?.variant.rarete ?? 'commune',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(view?.edition?.nom ?? '')),
        body: view == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 3.5,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                            child: InteractiveCard(view: view),
                          ),
                        ),
                      ),
                    ),
                    _Info(view: view, isPreview: preview != null),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${l.cardFlipHint} · ${l.cardTiltHint}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({required this.view, required this.isPreview});
  final CardView view;
  final bool isPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final color = AppColors.rarity[view.variant.rarete] ?? AppColors.steel;
    final fighter = view.fighter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(text: variantLabel(l, view.effect, view.variant.nom), color: color),
              _Chip(text: rarityLabel(l, view.variant.rarete), color: color),
              if (view.printRun != null) _Chip(text: l.cardPrintRun(view.printRun!), color: AppColors.gold),
              if (isPreview)
                _Chip(text: l.showcasePreview, color: AppColors.steel)
              else
                _Chip(
                  text: view.ownedCount == 0 ? l.notOwned : l.ownedCopies(view.ownedCount),
                  color: view.ownedCount == 0 ? AppColors.textMuted : AppColors.success,
                ),
            ],
          ),
          if (!isPreview && view.card != null) ...[
            const SizedBox(height: 10),
            VitrineToggleButton(cardId: view.card!.id, ownedId: view.owned?.id),
          ],
          if (fighter != null && !view.isDuel)
            TextButton.icon(
              onPressed: () => context.push('/combattants/${fighter.id}'),
              icon: const Icon(Icons.person_outline, size: 18),
              label: Text(fighter.nom),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

/// Utilisé par la vitrine pour ouvrir une vue construite à la main.
void openPreview(BuildContext context, CardView view) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CardDetailScreen(cardId: view.card?.id ?? '', preview: view),
    ),
  );
}

/// Raccourci : la meilleure rareté possédée d'une carte (pour l'album).
OwnedCard? bestOwned(List<OwnedCard> owned, Map<String, Variant> variants) {
  const order = ['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'];
  return owned.sortedBy<num>((o) => order.indexOf(variants[o.variantId]?.rarete ?? 'commune')).lastOrNull;
}
