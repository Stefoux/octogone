import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';

/// Liste des éditions (réelles et originales) avec leur complétion.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final editions = ref.watch(editionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.albumTitle)),
      body: editions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
        data: (list) {
          final real = list.where((e) => e.isReal).toList();
          final originals = list.where((e) => !e.isReal).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 30),
                  title: Text(l.effectsShowcase, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(l.effectsShowcaseSub),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/vitrine'),
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(l.noEditions)),
              if (originals.isNotEmpty) ...[
                _Header(l.originalEditions),
                for (final e in originals) _EditionTile(edition: e),
              ],
              if (real.isNotEmpty) ...[
                _Header(l.realEditions),
                for (final e in real) _EditionTile(edition: e),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
      );
}

class _EditionTile extends ConsumerWidget {
  const _EditionTile({required this.edition});
  final Edition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cards = ref.watch(cardsForEditionProvider(edition.id)).value ?? const <CardDef>[];
    final owned = ref.watch(ownedByCardProvider);
    final total = cards.length;
    final have = cards.where((c) => owned.containsKey(c.id)).length;
    final pct = total == 0 ? 0 : (100 * have / total).floor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/album/${edition.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 48,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: edition.familleCadre == 'chrome'
                        ? const [Color(0xFF8E9AAF), Color(0xFFE0E6EF), Color(0xFF6C7A91)]
                        : const [Color(0xFF14161C), Color(0xFFE8B04A), Color(0xFF14161C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text('${edition.annee}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(edition.nom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    edition.isReal ? l.editionCards(total) : '${l.editionCards(total)} · ${l.originalCreation}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : have / total,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l.completion(have, total, pct), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      ),
    );
  }
}
