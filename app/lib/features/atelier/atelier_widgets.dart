import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../boosters/booster_service.dart';
import '../cards/card_view.dart';
import '../cards/trading_card.dart';
import 'atelier_service.dart';

String atelierErrorMessage(AppLocalizations l, Object e) {
  final x = AtelierException.from(e);
  return switch (x.kind) {
    AtelierError.notEnoughFragments => l.atelierErrFragments,
    AtelierError.notRecyclable => l.atelierErrNotRecyclable,
    AtelierError.keepOne => l.atelierErrKeepOne,
    AtelierError.notCraftable => l.atelierErrNotCraftable,
    AtelierError.notEligible => l.atelierErrNotEligible,
    AtelierError.other => l.errorWithMessage(x.message ?? ''),
  };
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(key: const Key('atelier-confirm'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
      ],
    ),
  );
  return ok == true;
}

/// Fiche carte : protéger l'exemplaire, recycler un doublon de cette
/// variante, ou fabriquer la variante si elle manque.
class CardAtelierActions extends ConsumerStatefulWidget {
  const CardAtelierActions({super.key, required this.view, this.ownedId});
  final CardView view;
  final String? ownedId;

  @override
  ConsumerState<CardAtelierActions> createState() => _CardAtelierActionsState();
}

class _CardAtelierActionsState extends ConsumerState<CardAtelierActions> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      final msg = await action();
      if (msg != null) messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(atelierErrorMessage(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = widget.view;
    final cardId = view.card?.id;
    if (cardId == null) return const SizedBox.shrink();
    final service = ref.read(atelierServiceProvider);
    final copies = (ref.watch(ownedByCardProvider)[cardId] ?? const <OwnedCard>[])
        .where((o) => o.variantId == view.variant.id)
        .toList();
    final rates = ref.watch(fragmentRatesProvider).value ?? FragmentRates.fallback;

    if (copies.isNotEmpty) {
      final target = copies.firstWhereOrNull((o) => o.id == widget.ownedId) ?? copies.first;
      final dupes = ref.watch(duplicatesProvider).where((d) => copies.any((c) => c.id == d.owned.id)).toList();
      return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
        if (!target.isNumbered)
          TextButton.icon(
            key: const Key('atelier-protect'),
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await service.protect(target.id, !target.verrouillee);
                      return null;
                    }),
            icon: Icon(target.verrouillee ? Icons.lock : Icons.lock_open, size: 18),
            label: Text(target.verrouillee ? l.atelierProtected : l.atelierProtect),
          ),
        if (dupes.isNotEmpty)
          TextButton.icon(
            key: const Key('atelier-recycle-one'),
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final r = await service.recycle([dupes.first.owned.id]);
                      unawaited(HapticFeedback.lightImpact());
                      return l.atelierRecycled(r.gained, r.cards);
                    }),
            icon: const Icon(Icons.recycling, size: 18),
            label: Text(l.atelierRecycleOne(dupes.first.gain)),
          ),
      ]);
    }

    final cost = rates.craftCost(view.variant, series: view.series);
    if (cost == null) return const SizedBox.shrink();
    final fragments = ref.watch(walletProvider).value?.fragments ?? 0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      FilledButton.tonalIcon(
        key: const Key('atelier-craft'),
        onPressed: _busy || fragments < cost
            ? null
            : () async {
                if (!await _confirm(context, l.atelierCraftTitle, l.atelierCraftConfirm(cost))) return;
                await _run(() async {
                  await service.craft(cardId, view.variant.id);
                  unawaited(HapticFeedback.mediumImpact());
                  return l.atelierCrafted;
                });
              },
        icon: const Icon(Icons.construction, size: 18),
        label: Text(l.atelierCraft(cost)),
      ),
      const SizedBox(height: 4),
      Text(l.atelierFragments(fragments), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    ]);
  }
}

/// Atelier (onglet de la Boutique) : solde de fragments, recyclage de tous
/// les doublons d'un coup, liste des doublons, aide à la fabrication.
class AtelierView extends ConsumerStatefulWidget {
  const AtelierView({super.key});

  @override
  ConsumerState<AtelierView> createState() => _AtelierViewState();
}

class _AtelierViewState extends ConsumerState<AtelierView> {
  bool _busy = false;

  Future<void> _recycleAll(List<Duplicate> dupes) async {
    final l = context.l10n;
    final gain = dupes.map((d) => d.gain).sum;
    if (!await _confirm(context, l.atelierRecycleConfirmTitle(dupes.length), l.atelierRecycleConfirm(gain))) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref.read(atelierServiceProvider).recycle([for (final d in dupes) d.owned.id]);
      unawaited(HapticFeedback.mediumImpact());
      messenger.showSnackBar(SnackBar(content: Text(l.atelierRecycled(r.gained, r.cards))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(atelierErrorMessage(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fragments = ref.watch(walletProvider).value?.fragments;
    final dupes = ref.watch(duplicatesProvider);
    final gain = dupes.map((d) => d.gain).sum;
    final byCard = groupBy(dupes, (Duplicate d) => '${d.owned.cardId}|${d.owned.variantId}');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.diamond_outlined, color: AppColors.gold, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fragments == null ? '–' : l.atelierFragments(fragments),
                  key: const Key('atelier-balance'),
                  style: const TextStyle(fontFamily: kDisplayFont, fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.atelierRecycleAll, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                dupes.isEmpty ? l.atelierNoDuplicates : l.atelierRecycleAllSub(dupes.length, gain),
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('atelier-recycle-all'),
                onPressed: dupes.isEmpty || _busy ? null : () => _recycleAll(dupes),
                icon: const Icon(Icons.recycling),
                label: Text(l.atelierRecycleAll),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              Text(l.atelierRules, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ]),
          ),
        ),
        if (byCard.isNotEmpty) ...[
          const SizedBox(height: 18),
          for (final group in byCard.values) _DuplicateRow(group: group),
        ],
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.construction),
            title: Text(l.atelierCraftHelpTitle),
            subtitle: Text(l.atelierCraftHelp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/album'),
          ),
        ),
      ],
    );
  }
}

class _DuplicateRow extends ConsumerWidget {
  const _DuplicateRow({required this.group});
  final List<Duplicate> group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final first = group.first;
    final view = buildCardView(ref, cardId: first.owned.cardId, owned: first.owned);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 44, child: view == null ? const SizedBox() : TradingCard(view: view, animate: false)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(view == null ? '' : cardTitle(l, view), style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(rarityLabel(l, first.rarete),
                style: TextStyle(color: AppColors.rarity[first.rarete], fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
        ),
        Text('×${group.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        Text('+${group.map((d) => d.gain).sum}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

