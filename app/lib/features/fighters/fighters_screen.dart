import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';

/// Ordre des catégories : hommes du plus lourd au plus léger, puis femmes.
const kWeightClassOrder = [
  WeightClass.lourds,
  WeightClass.miLourds,
  WeightClass.moyens,
  WeightClass.miMoyens,
  WeightClass.legers,
  WeightClass.plume,
  WeightClass.coq,
  WeightClass.mouche,
  WeightClass.plumeF,
  WeightClass.coqF,
  WeightClass.moucheF,
  WeightClass.pailleF,
];

enum FighterSort { classement, note, nom, pays }

/// Rang affiché dans une catégorie : champion (0), classé (1 à 15), sinon null.
int? rankIn(Fighter f, WeightClass w) {
  final c = f.classement;
  return c != null && c.categorie == w ? c.rang : null;
}

/// Combattants rangés par catégorie de poids : une rangée par catégorie à
/// faire défiler sur le côté (le champion, puis les classés, puis les autres),
/// ou une grille quand une catégorie est choisie. Recherche, tri, style et
/// « mes combattants ».
class FightersScreen extends ConsumerStatefulWidget {
  const FightersScreen({super.key});

  @override
  ConsumerState<FightersScreen> createState() => _FightersScreenState();
}

class _FightersScreenState extends ConsumerState<FightersScreen> {
  String _query = '';
  WeightClass? _division;
  FighterStyle? _style;
  FighterSort _sort = FighterSort.classement;
  bool _mine = false;

  bool _match(Fighter f, Set<String> owned) {
    if (_style != null && f.stats.style != _style) return false;
    if (_mine && !owned.contains(f.id)) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return f.nom.toLowerCase().contains(q) || (f.surnom?.toLowerCase().contains(q) ?? false);
  }

  List<Fighter> _sorted(BuildContext context, List<Fighter> list, WeightClass w) {
    int byOverall(Fighter a, Fighter b) => b.stats.overall.compareTo(a.stats.overall);
    return switch (_sort) {
      FighterSort.classement => list.sorted((a, b) {
        final ra = rankIn(a, w) ?? 99, rb = rankIn(b, w) ?? 99;
        return ra != rb ? ra.compareTo(rb) : byOverall(a, b);
      }),
      FighterSort.note => list.sorted(byOverall),
      FighterSort.nom => list.sorted((a, b) => a.nom.compareTo(b.nom)),
      FighterSort.pays => list.sorted((a, b) {
        final c = countryLabel(context, a.pays).compareTo(countryLabel(context, b.pays));
        return c != 0 ? c : a.nom.compareTo(b.nom);
      }),
    };
  }

  Future<T?> _menu<T>(String title, List<(T?, String)> options, T? current) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == current ? const Icon(Icons.check, color: AppColors.gold) : null,
              // null : « toutes » (renvoyé comme -1 pour distinguer d'une fermeture)
              onTap: () => Navigator.pop(ctx, value ?? _none),
            ),
        ],
      ),
    ),
  ).then((v) => v);

  static const _none = #none;

  Future<void> _pickDivision() async {
    final l = context.l10n;
    final v = await _menu<Object>(l.fightersAllClasses, [
      (null, l.fightersAllClasses),
      for (final w in kWeightClassOrder) (w, weightClassLabel(l, w)),
    ], _division);
    if (v == null) return;
    setState(() => _division = v == _none ? null : v as WeightClass);
  }

  Future<void> _pickStyle() async {
    final l = context.l10n;
    final v = await _menu<Object>(l.fightersStyle, [
      (null, l.fightersAllStyles),
      for (final st in FighterStyle.values) (st, styleLabel(l, st)),
    ], _style);
    if (v == null) return;
    setState(() => _style = v == _none ? null : v as FighterStyle);
  }

  Future<void> _pickSort() async {
    final l = context.l10n;
    final v = await _menu<Object>(l.fightersSort, [for (final s in FighterSort.values) (s, _sortLabel(l, s))], _sort);
    if (v is FighterSort) setState(() => _sort = v);
  }

  static String _sortLabel(AppLocalizations l, FighterSort s) => switch (s) {
    FighterSort.classement => l.fightersSortRanking,
    FighterSort.note => l.fightersSortOverall,
    FighterSort.nom => l.fightersSortName,
    FighterSort.pays => l.fightersSortCountry,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fighters = ref.watch(fightersProvider);
    final cards = ref.watch(allCardsProvider).value ?? const <String, CardDef>{};
    final owned = {
      for (final o in ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[]) ...?cards[o.cardId]?.fighterIds,
    };
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.fightersTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('fighters-search'),
              decoration: InputDecoration(hintText: l.searchFighters, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          // Tous les filtres visibles d'un coup (sur deux lignes au besoin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              runSpacing: 4,
              children: [
                _FilterButton(
                  key: const Key('fighters-division'),
                  icon: Icons.scale_outlined,
                  label: _division == null ? l.fightersAllClasses : weightClassLabel(l, _division),
                  active: _division != null,
                  onTap: _pickDivision,
                ),
                _FilterButton(
                  key: const Key('fighters-sort'),
                  icon: Icons.sort,
                  label: _sortLabel(l, _sort),
                  active: _sort != FighterSort.classement,
                  onTap: _pickSort,
                ),
                _FilterButton(
                  key: const Key('fighters-style'),
                  icon: Icons.sports_mma,
                  label: _style == null ? l.fightersStyle : styleLabel(l, _style!),
                  active: _style != null,
                  onTap: _pickStyle,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    key: const Key('fighters-mine'),
                    label: Text(l.fightersMine),
                    selected: _mine,
                    onSelected: (v) => setState(() => _mine = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: fighters.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
              data: (all) {
                if (all.isEmpty) return const _EmptyCache();
                final byClass = groupBy(
                  all.where((f) => f.categorie != null && _match(f, owned)),
                  (Fighter f) => f.categorie!,
                );
                final classes = [
                  for (final w in kWeightClassOrder)
                    if ((byClass[w] ?? const []).isNotEmpty) w,
                ];
                final Widget body;
                if (_division != null) {
                  final list = _sorted(context, byClass[_division] ?? const [], _division!);
                  body = list.isEmpty
                      ? ListView(children: [_NoMatch(text: l.fightersNoMatch)])
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 150,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.66,
                          ),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _FighterTile(
                            fighter: list[i],
                            rank: rankIn(list[i], _division!),
                            owned: owned.contains(list[i].id),
                          ),
                        );
                } else if (classes.isEmpty) {
                  body = ListView(children: [_NoMatch(text: l.fightersNoMatch)]);
                } else {
                  body = ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: classes.length,
                    itemBuilder: (_, i) {
                      final w = classes[i];
                      final list = _sorted(context, byClass[w]!, w);
                      return _ClassRow(
                        key: Key('fighters-row-${w.key}'),
                        title: weightClassLabel(l, w),
                        count: list.length,
                        onSeeAll: () => setState(() => _division = w),
                        children: [
                          for (final f in list)
                            _FighterTile(fighter: f, rank: rankIn(f, w), owned: owned.contains(f.id), width: 112),
                        ],
                      );
                    },
                  );
                }
                return RefreshIndicator(onRefresh: () => ref.read(syncControllerProvider.notifier).sync(), child: body);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({super.key, required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ActionChip(
      avatar: Icon(icon, size: 18, color: active ? AppColors.gold : AppColors.textMuted),
      label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)]),
      side: BorderSide(color: active ? AppColors.gold : AppColors.outline),
      onPressed: onTap,
    ),
  );
}

/// Une catégorie : titre, nombre, « Tout voir », combattants à faire défiler.
class _ClassRow extends StatelessWidget {
  const _ClassRow({
    super.key,
    required this.title,
    required this.count,
    required this.onSeeAll,
    required this.children,
  });
  final String title;
  final int count;
  final VoidCallback onSeeAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${title.toUpperCase()}  ·  $count',
                  style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 15,
                    letterSpacing: 1.2,
                    color: AppColors.gold,
                  ),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: Text(l.fightersSeeAll)),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => children[i],
          ),
        ),
      ],
    );
  }
}

/// Un combattant : photo, rang (ceinture ou n°), note, drapeau, nom.
class _FighterTile extends StatelessWidget {
  const _FighterTile({required this.fighter, required this.rank, required this.owned, this.width});
  final Fighter fighter;
  final int? rank;
  final bool owned;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final f = fighter;
    final champion = rank == 0;
    final tile = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/combattants/${f.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: champion ? AppColors.gold : AppColors.outline, width: champion ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FighterPortrait(imageId: f.imageId, borderRadius: 0),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: rank == null
                          ? const SizedBox.shrink()
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: champion ? AppColors.gold : Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: champion
                                  ? const Icon(Icons.emoji_events, size: 14, color: Colors.black)
                                  : Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                            ),
                    ),
                    Positioned(right: 4, top: 4, child: OverallBadge(value: f.stats.overall, size: 28)),
                    if (owned)
                      const Positioned(right: 4, bottom: 4, child: Icon(Icons.style, size: 16, color: AppColors.gold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                child: Text(
                  '${flagEmoji(f.pays)} ${f.nom}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return width == null ? tile : SizedBox(width: width, child: tile);
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textMuted),
    ),
  );
}

class _EmptyCache extends ConsumerWidget {
  const _EmptyCache();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              sync.running
                  ? l.downloadingFighters
                  : sync.error != null
                  ? l.downloadFailed
                  : l.noFighters,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (!sync.running)
              OutlinedButton(onPressed: () => ref.read(syncControllerProvider.notifier).sync(), child: Text(l.retry)),
          ],
        ),
      ),
    );
  }
}
