import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../cards/card_detail_screen.dart' show bestOwned;
import '../cards/card_view.dart';
import '../cards/trading_card.dart';

/// Classeur d'une édition : pages de 9 emplacements (3×3) qu'on tourne du
/// doigt, emplacements vides numérotés, complétion, filtres. Une vue
/// « Checklist » liste aussi séries, parallèles et tirages.
class BinderScreen extends ConsumerStatefulWidget {
  const BinderScreen({super.key, required this.editionId});
  final String editionId;

  @override
  ConsumerState<BinderScreen> createState() => _BinderScreenState();
}

class _BinderScreenState extends ConsumerState<BinderScreen> {
  String? _seriesId;
  bool _checklist = false;
  String? _rarity;
  WeightClass? _division;
  bool _ownedOnly = false;
  String _query = '';
  final _page = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _resetPage() {
    _pageIndex = 0;
    if (_page.hasClients) _page.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final edition = ref.watch(editionsByIdProvider)[widget.editionId];
    final series = ref.watch(seriesForEditionProvider(widget.editionId)).value ?? const <CardSeries>[];
    final cards = ref.watch(cardsForEditionProvider(widget.editionId)).value ?? const <CardDef>[];
    final variants = ref.watch(allVariantsProvider).value ?? const <String, Variant>{};
    final owned = ref.watch(ownedByCardProvider);
    final fighters = ref.watch(fightersByIdProvider);

    if (edition == null || series.isEmpty) {
      return Scaffold(
          backgroundColor: Colors.transparent, appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final current = series.firstWhereOrNull((s) => s.id == _seriesId) ?? series.first;
    final inSeries = cards.where((c) => c.seriesId == current.id).toList();

    bool matches(CardDef c) {
      final mine = owned[c.id] ?? const <OwnedCard>[];
      if (_ownedOnly && mine.isEmpty) return false;
      if (_rarity != null) {
        if (!mine.any((o) => variants[o.variantId]?.rarete == _rarity)) return false;
      }
      final fs = [for (final id in c.fighterIds) ?fighters[id]];
      if (_division != null && !fs.any((f) => f.categorie == _division)) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!c.nomImprime.toLowerCase().contains(q) && !fs.any((f) => f.nom.toLowerCase().contains(q))) return false;
      }
      return true;
    }

    final visible = inSeries.where(matches).toList();
    final haveSeries = inSeries.where((c) => owned.containsKey(c.id)).length;
    final pct = inSeries.isEmpty ? 0 : (100 * haveSeries / inSeries.length).floor();
    final pages = (visible.length / 9).ceil().clamp(1, 1 << 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(edition.nom),
        actions: [
          IconButton(
            tooltip: _checklist ? l.binderView : l.checklistView,
            icon: Icon(_checklist ? Icons.grid_view : Icons.list_alt),
            onPressed: () => setState(() => _checklist = !_checklist),
          ),
        ],
      ),
      body: Column(
        children: [
          // Séries
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final s in series)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(s.nom),
                      selected: s.id == current.id,
                      onSelected: (_) => setState(() {
                        _seriesId = s.id;
                        _resetPage();
                      }),
                    ),
                  ),
              ],
            ),
          ),
          // Complétion de la série
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: inSeries.isEmpty ? 0 : haveSeries / inSeries.length,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(l.completion(haveSeries, inSeries.length, pct),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          _Filters(
            rarity: _rarity,
            division: _division,
            ownedOnly: _ownedOnly,
            onRarity: (v) => setState(() {
              _rarity = v;
              _resetPage();
            }),
            onDivision: (v) => setState(() {
              _division = v;
              _resetPage();
            }),
            onOwnedOnly: (v) => setState(() {
              _ownedOnly = v;
              _resetPage();
            }),
            onQuery: (v) => setState(() {
              _query = v.trim();
              _resetPage();
            }),
          ),
          Expanded(
            child: _checklist
                ? _Checklist(series: current, cards: visible, variants: variants, owned: owned)
                : Column(children: [
                    Expanded(
                      child: PageView.builder(
                        key: ValueKey('${current.id}-${visible.length}'),
                        controller: _page,
                        itemCount: pages,
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        itemBuilder: (context, page) {
                          final slice = visible.skip(page * 9).take(9).toList();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                            child: _Page(cards: slice, variants: variants, owned: owned),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l.pageOf(_pageIndex + 1, pages),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.rarity,
    required this.division,
    required this.ownedOnly,
    required this.onRarity,
    required this.onDivision,
    required this.onOwnedOnly,
    required this.onQuery,
  });

  final String? rarity;
  final WeightClass? division;
  final bool ownedOnly;
  final ValueChanged<String?> onRarity;
  final ValueChanged<WeightClass?> onDivision;
  final ValueChanged<bool> onOwnedOnly;
  final ValueChanged<String> onQuery;

  static const rarities = ['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 40,
            child: TextField(
              key: const Key('binder-search'),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: l.filterSearchFighter,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
              ),
              onChanged: onQuery,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _Menu<String?>(
          icon: Icons.diamond_outlined,
          active: rarity != null,
          tooltip: rarity == null ? l.filterAllRarities : rarityLabel(l, rarity!),
          items: [
            (null, l.filterAllRarities, null),
            for (final r in rarities) (r, rarityLabel(l, r), AppColors.rarity[r]),
          ],
          onSelected: onRarity,
        ),
        _Menu<WeightClass?>(
          icon: Icons.monitor_weight_outlined,
          active: division != null,
          tooltip: division == null ? l.filterAllCategories : weightClassLabel(l, division),
          items: [
            (null, l.filterAllCategories, null),
            for (final w in WeightClass.values) (w, weightClassLabel(l, w), null),
          ],
          onSelected: onDivision,
        ),
        FilterChip(
          label: Text(l.filterOwnedOnly, style: const TextStyle(fontSize: 12)),
          selected: ownedOnly,
          onSelected: onOwnedOnly,
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}

class _Menu<T> extends StatelessWidget {
  const _Menu({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.items,
    required this.onSelected,
  });
  final IconData icon;
  final bool active;
  final String tooltip;
  final List<(T, String, Color?)> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
        tooltip: tooltip,
        icon: Icon(icon, color: active ? AppColors.gold : null),
        onSelected: (i) => onSelected(items[i].$1),
        itemBuilder: (_) => [
          for (var i = 0; i < items.length; i++)
            PopupMenuItem(
              value: i,
              child: Row(children: [
                if (items[i].$3 != null) ...[
                  Icon(Icons.circle, size: 10, color: items[i].$3),
                  const SizedBox(width: 8),
                ],
                Text(items[i].$2),
              ]),
            ),
        ],
      );
}

class _Page extends ConsumerWidget {
  const _Page({required this.cards, required this.variants, required this.owned});
  final List<CardDef> cards;
  final Map<String, Variant> variants;
  final Map<String, List<OwnedCard>> owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, c) {
      // 3 colonnes, 3 rangées : la taille des cartes suit la place disponible.
      const gap = 8.0;
      final byWidth = (c.maxWidth - 2 * gap) / 3;
      final byHeight = ((c.maxHeight - 2 * gap) / 3) * kCardAspect;
      final w = byWidth < byHeight ? byWidth : byHeight;
      return Center(
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 9; i++)
              SizedBox(
                width: w,
                height: w / kCardAspect,
                child: i < cards.length ? _Slot(card: cards[i], variants: variants, owned: owned) : const SizedBox(),
              ),
          ],
        ),
      );
    });
  }
}

class _Slot extends ConsumerWidget {
  const _Slot({required this.card, required this.variants, required this.owned});
  final CardDef card;
  final Map<String, Variant> variants;
  final Map<String, List<OwnedCard>> owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = owned[card.id] ?? const <OwnedCard>[];
    final best = bestOwned(mine, variants);
    if (best == null) {
      return GestureDetector(
        onTap: () => context.push('/carte/${Uri.encodeComponent(card.id)}'),
        child: _EmptySlot(card: card),
      );
    }
    final view = buildCardView(ref, cardId: card.id, owned: best);
    if (view == null) return _EmptySlot(card: card);
    return GestureDetector(
      onTap: () => context.push('/carte/${Uri.encodeComponent(card.id)}?owned=${best.id}'),
      child: Stack(children: [
        TradingCard(view: view, animate: false),
        if (mine.length > 1)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(8)),
              child: Text('×${mine.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.card});
  final CardDef card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline, width: 1.2),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.numero,
              style: const TextStyle(fontFamily: 'Oswald', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(card.tactique != null ? tacticName(context.l10n, card.tactique!) : card.nomImprime,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.series, required this.cards, required this.variants, required this.owned});
  final CardSeries series;
  final List<CardDef> cards;
  final Map<String, Variant> variants;
  final Map<String, List<OwnedCard>> owned;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parallels = variants.values.where((v) => v.seriesId == series.id).sortedBy<num>((v) => v.ordre).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text([
          seriesTypeLabel(l, series.type),
          if (series.tirage != null) l.numberedSeries(series.tirage!),
          if (series.cote != null) l.oddsLabel(series.cote!),
          ?series.exclusivite,
        ].join(' · '), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        if (parallels.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(l.parallels, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final v in parallels)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (AppColors.rarity[v.rarete] ?? AppColors.steel).withValues(alpha: 0.6)),
                  color: (AppColors.rarity[v.rarete] ?? AppColors.steel).withValues(alpha: 0.1),
                ),
                child: Text(
                  [variantLabel(l, v.effet, v.nom), if (v.tirage != null) v.tirageLabel].join(' '),
                  style: TextStyle(fontSize: 12, color: AppColors.rarity[v.rarete], fontWeight: FontWeight.w600),
                ),
              ),
          ]),
        ],
        const SizedBox(height: 12),
        for (final c in cards)
          InkWell(
            onTap: () => context.push('/carte/${Uri.encodeComponent(c.id)}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                Icon(owned.containsKey(c.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18, color: owned.containsKey(c.id) ? AppColors.success : AppColors.outline),
                const SizedBox(width: 10),
                SizedBox(width: 64, child: Text(c.numero, style: const TextStyle(color: AppColors.textMuted))),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: c.tactique != null ? tacticName(l, c.tactique!) : c.nomImprime,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (c.sousTitre != null)
                      TextSpan(text: '  « ${c.sousTitre} »', style: const TextStyle(color: AppColors.textMuted)),
                  ])),
                ),
                if (c.isRookie)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(4)),
                    child: const Text('RC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
              ]),
            ),
          ),
      ],
    );
  }
}
