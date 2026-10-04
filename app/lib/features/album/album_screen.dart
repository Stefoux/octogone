import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';

/// Liste des éditions (réelles et originales). Le classeur avec emplacements
/// vides et pourcentage de complétion arrive en phase 2.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editions = ref.watch(editionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Album')),
      body: editions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune édition en cache pour l’instant.'));
          }
          final real = list.where((e) => e.isReal).toList();
          final originals = list.where((e) => !e.isReal).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (real.isNotEmpty) ...[
                const _Header('Éditions réelles'),
                for (final e in real) _EditionTile(edition: e),
              ],
              if (originals.isNotEmpty) ...[
                const _Header('Éditions originales'),
                for (final e in originals) _EditionTile(edition: e),
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
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
      );
}

class _EditionTile extends ConsumerWidget {
  const _EditionTile({required this.edition});
  final Edition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsForEditionProvider(edition.id)).value ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 48,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: edition.familleCadre == 'chrome'
                    ? const [Color(0xFF8E9AAF), Color(0xFFE0E6EF), Color(0xFF6C7A91)]
                    : const [Color(0xFF3A2E1F), Color(0xFFE8B04A), Color(0xFF3A2E1F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text('${edition.annee}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          title: Text(edition.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${cards.length} cartes${edition.isReal ? '' : ' · création originale'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/album/${edition.id}'),
        ),
      ),
    );
  }
}
