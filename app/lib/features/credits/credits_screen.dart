import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';

/// Attributions des photos (licences libres Wikimedia Commons) et sources des
/// données. Exigé par les licences CC BY / CC BY-SA.
class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  static const _dataSources = [
    ('Statistiques officielles des combattants', 'ufc.com (fiches athlètes)', 'https://www.ufc.com/athletes'),
    ('Palmarès détaillés, distinctions', 'Wikipedia (en anglais)', 'https://en.wikipedia.org/'),
    ('Nationalité, date de naissance', 'Wikidata', 'https://www.wikidata.org/'),
    ('Checklists des éditions réelles', 'Checklist Insider', 'https://www.checklistinsider.com/'),
    ('Recoupement des checklists', 'Checklist Center', 'https://www.checklistcenter.com/'),
    ('Photos', 'Wikimedia Commons (licences libres)', 'https://commons.wikimedia.org/'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = (ref.watch(imagesProvider).value ?? const <String, ImageRef>{}).values.toList()
      ..sort((a, b) => (a.titre ?? '').compareTo(b.titre ?? ''));
    final fighters = {for (final f in ref.watch(fightersProvider).value ?? const <Fighter>[]) f.id: f.nom};

    return Scaffold(
      appBar: AppBar(title: const Text('Crédits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Application personnelle, non commerciale et non officielle. Aucun logo officiel : '
            'les noms d’éditions apparaissent en texte et les cadres des cartes sont des créations originales.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text('Sources des données', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          for (final (what, who, url) in _dataSources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(who),
              subtitle: Text(what),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          const SizedBox(height: 16),
          Text('Photos (${images.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          if (images.isEmpty) const Text('Aucune photo synchronisée.', style: TextStyle(color: AppColors.textMuted)),
          for (final img in images)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(fighters[img.fighterId] ?? img.titre ?? img.storagePath),
              subtitle: Text(
                [
                  if (img.auteur != null) 'Auteur : ${img.auteur}',
                  if (img.licence != null) 'Licence : ${img.licence}',
                ].join('\n'),
              ),
              isThreeLine: img.auteur != null && img.licence != null,
              trailing: img.sourceUrl == null ? null : const Icon(Icons.open_in_new, size: 18),
              onTap: img.sourceUrl == null
                  ? null
                  : () => launchUrl(Uri.parse(img.sourceUrl!), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }
}
