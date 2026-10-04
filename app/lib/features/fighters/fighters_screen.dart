import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';

class FightersScreen extends ConsumerStatefulWidget {
  const FightersScreen({super.key});

  @override
  ConsumerState<FightersScreen> createState() => _FightersScreenState();
}

class _FightersScreenState extends ConsumerState<FightersScreen> {
  String _query = '';
  WeightClass? _division;
  bool _championsOnly = false;

  bool _match(Fighter f) {
    if (_division != null && f.categorie != _division) return false;
    if (_championsOnly && !f.championActuel) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return f.nom.toLowerCase().contains(q) || (f.surnom?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fighters = ref.watch(fightersProvider);
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
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(l.champions),
                    selected: _championsOnly,
                    onSelected: (v) => setState(() => _championsOnly = v),
                  ),
                ),
                for (final w in WeightClass.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(weightClassShort(l, w)),
                      selected: _division == w,
                      onSelected: (v) => setState(() => _division = v ? w : null),
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
                final list = all.where(_match).toList();
                if (all.isEmpty) {
                  return const _EmptyCache();
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(syncControllerProvider.notifier).sync(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _FighterTile(fighter: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FighterTile extends StatelessWidget {
  const _FighterTile({required this.fighter});
  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final f = fighter;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/combattants/${f.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(width: 56, height: 56, child: FighterPortrait(imageId: f.imageId)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(flagEmoji(f.pays)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(f.nom,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        if (f.championActuel) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.emoji_events, size: 16, color: AppColors.gold),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (f.surnom != null) '« ${f.surnom} »',
                        weightClassLabel(context.l10n, f.categorie),
                        f.record,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              OverallBadge(value: f.stats.overall),
            ],
          ),
        ),
      ),
    );
  }
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
              OutlinedButton(
                onPressed: () => ref.read(syncControllerProvider.notifier).sync(),
                child: Text(l.retry),
              ),
          ],
        ),
      ),
    );
  }
}
