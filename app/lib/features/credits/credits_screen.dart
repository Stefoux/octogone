import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';

/// Attributions des photos (licences libres Wikimedia Commons) et sources des
/// données. Exigé par les licences CC BY / CC BY-SA.
class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = (ref.watch(imagesProvider).value ?? const <String, ImageRef>{}).values.toList()
      ..sort((a, b) => (a.titre ?? '').compareTo(b.titre ?? ''));
    final fighters = {for (final f in ref.watch(fightersProvider).value ?? const <Fighter>[]) f.id: f.nom};
    final l = context.l10n;
    final dataSources = [
      (l.srcStats, 'ufc.com', 'https://www.ufc.com/athletes'),
      (l.srcRecords, 'Wikipedia', 'https://en.wikipedia.org/'),
      (l.srcNationality, 'Wikidata', 'https://www.wikidata.org/'),
      (l.srcChecklists, 'Checklist Insider', 'https://www.checklistinsider.com/'),
      (l.srcChecklistCheck, 'Checklist Center', 'https://www.checklistcenter.com/'),
      (l.srcPhotos, l.srcPhotosWho, 'https://commons.wikimedia.org/'),
      (l.srcFont, 'Google Fonts', 'https://fonts.google.com/specimen/Oswald'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.creditsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.creditsDisclaimer, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Text(l.dataSources, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          for (final (what, who, url) in dataSources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(who),
              subtitle: Text(what),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          ListTile(contentPadding: EdgeInsets.zero, title: Text(l.srcSoundsWho), subtitle: Text(l.srcSounds)),
          const SizedBox(height: 16),
          Text(l.photosCount(images.length), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          if (images.isEmpty) Text(l.noPhotos, style: const TextStyle(color: AppColors.textMuted)),
          for (final img in images)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(fighters[img.fighterId] ?? img.titre ?? img.storagePath),
              subtitle: Text(
                [
                  if (img.auteur != null) l.photoAuthor(img.auteur!),
                  if (img.licence != null) l.photoLicense(img.licence!),
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
