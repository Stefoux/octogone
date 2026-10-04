import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import 'booster_pack.dart';
import 'booster_service.dart';

/// Mode de paiement d'une ouverture : recharge gratuite si possible, sinon
/// pièces (après confirmation). null si le joueur renonce.
Future<String?> choosePayment(BuildContext context, WidgetRef ref, BoosterType b) async {
  final l = context.l10n;
  BoosterStatus? status;
  try {
    status = await ref.read(boosterStatusProvider.future);
  } catch (_) {}
  if (status == null || status.testMode) return 'gratuit';
  if (b.type == 'standard' && status.charges > 0) return 'gratuit';
  if (!context.mounted) return null;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(b.type == 'standard' ? l.boosterNoFree : b.nom),
      content: Text(l.boosterPayWithCoins(b.prixPieces)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
      ],
    ),
  );
  return ok == true ? 'pieces' : null;
}

String boosterErrorMessage(AppLocalizations l, Object e) {
  if (e is BoosterException) {
    return switch (e.kind) {
      BoosterError.noFreePack => l.boosterNoFree,
      BoosterError.notEnoughCoins => l.boosterNotEnoughCoins,
      BoosterError.unavailable => l.boosterUnavailable,
      BoosterError.other => l.errorWithMessage(e.message ?? ''),
    };
  }
  return l.errorWithMessage('$e');
}

/// « 11 h 32 min » / « 5 min »
String formatDuration(AppLocalizations l, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60) + (d.inSeconds.remainder(60) > 0 ? 1 : 0);
  if (h > 0) return l.durationHm(h, m.clamp(0, 59));
  return l.durationM(m.clamp(1, 60));
}

/// Fiche des probabilités d'un booster (calculées depuis sa composition).
Future<void> showOddsSheet(BuildContext context, WidgetRef ref, BoosterType b) {
  final l = context.l10n;
  final odds = PackOdds.fromComposition(b.composition);
  final status = ref.read(boosterStatusProvider).value;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${l.boosterOdds} · ${b.nom}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final r in Rarity.values)
            if ((odds.atLeastOne[r] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Icon(Icons.diamond, size: 16, color: AppColors.rarity[r.key]),
                  const SizedBox(width: 10),
                  Expanded(child: Text(rarityLabel(l, r.key), style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(_oddsText(l, odds, r), style: const TextStyle(color: AppColors.textMuted)),
                ]),
              ),
          const Divider(height: 24),
          if (status != null) ...[
            Text(l.boosterPity(status.pityThreshold)),
            Text(l.boosterPityLeft(status.pityLeft), style: const TextStyle(color: AppColors.gold)),
            const SizedBox(height: 8),
          ],
          Text(l.boosterNumberedNote, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      ),
    ),
  );
}

String _oddsText(AppLocalizations l, PackOdds o, Rarity r) {
  final p = o.atLeastOne[r]!;
  if (p >= 0.995) {
    final n = o.perPack[r]!;
    return l.boosterOddsPerPack(n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1));
  }
  if (p >= 0.5) return l.boosterOddsPercent((p * 100).round());
  return l.boosterOddsOneIn(o.oneIn(r)!);
}

/// Choix de la collection affichée sur l'accueil.
Future<void> showCollectionsSheet(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
    builder: (ctx) => Consumer(builder: (ctx, ref, _) {
      final all = (ref.watch(boosterTypesProvider).value ?? const <BoosterType>[])
          .where((b) => b.availableAt(DateTime.now()))
          .toList();
      final byEdition = groupBy(all, (BoosterType b) => b.editionId);
      final current = ref.watch(currentBoostersProvider).firstOrNull?.editionId;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.boosterCollectionsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final entry in byEdition.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: entry.key == current ? AppColors.gold.withValues(alpha: 0.12) : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      ref.read(selectedCollectionProvider.notifier).select(entry.key);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        SizedBox(height: 92, child: BoosterPack(booster: entry.value.first, animate: false)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(entry.value.first.nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              entry.value
                                  .map((b) => '${b.isPremium ? l.boosterPremium : l.boosterStandard} · ${l.boosterCards(b.nbCartes)}')
                                  .join('\n'),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ]),
                        ),
                        if (entry.key == current) const Icon(Icons.check_circle, color: AppColors.gold),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
    }),
  );
}
