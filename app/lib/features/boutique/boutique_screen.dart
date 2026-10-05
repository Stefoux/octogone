import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../atelier/atelier_widgets.dart';
import '../boosters/booster_pack.dart';
import '../boosters/booster_service.dart';
import '../defis/defis_service.dart';

/// Boutique : boosters à acheter en pièces et Atelier (recyclage,
/// fabrication). Pas d'argent réel.
class BoutiqueScreen extends ConsumerStatefulWidget {
  const BoutiqueScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends ConsumerState<BoutiqueScreen> {
  int get initialTab => widget.initialTab;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(walletProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final wallet = ref.watch(walletProvider).value;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l.shopTitle),
          actions: [
            const Icon(Icons.toll, color: AppColors.gold, size: 20),
            const SizedBox(width: 4),
            Text(wallet == null ? '–' : '${wallet.pieces}',
                key: const Key('shop-coins'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            const Icon(Icons.diamond_outlined, color: AppColors.textMuted, size: 19),
            const SizedBox(width: 4),
            Text(wallet == null ? '–' : '${wallet.fragments}', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 16),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.text,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontFamily: kBodyFont, fontWeight: FontWeight.w700, fontSize: 15),
            tabs: [
              Tab(key: const Key('shop-tab-boosters'), text: l.shopBoosters),
              Tab(key: const Key('shop-tab-atelier'), text: l.atelierTitle),
            ],
          ),
        ),
        body: const TabBarView(children: [_BoostersShop(), AtelierView()]),
      ),
    );
  }
}

class _BoostersShop extends ConsumerWidget {
  const _BoostersShop();

  Future<void> _buy(BuildContext context, WidgetRef ref, BoosterType b, bool testMode) async {
    final l = context.l10n;
    if (!testMode) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(b.nom),
          content: Text(l.boosterPayWithCoins(b.prixPieces)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(key: const Key('shop-confirm'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    await context.push('/booster/${Uri.encodeComponent(b.id)}?paiement=pieces');
    ref
      ..invalidate(walletProvider)
      ..invalidate(boosterStatusProvider)
      ..invalidate(defisProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final all = (ref.watch(boosterTypesProvider).value ?? const <BoosterType>[])
        .where((b) => b.availableAt(DateTime.now()))
        .toList();
    final testMode = ref.watch(boosterStatusProvider).value?.testMode ?? false;
    final coins = ref.watch(walletProvider).value?.pieces ?? 0;
    final byEdition = groupBy(all, (BoosterType b) => b.editionId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (testMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              const Icon(Icons.all_inclusive, size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              Expanded(child: Text(l.boosterTestMode, style: const TextStyle(color: AppColors.gold, fontSize: 13))),
            ]),
          ),
        for (final entry in byEdition.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
            child: Text(entry.value.first.nom.toUpperCase(),
                style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.85), letterSpacing: 2.5, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          for (final b in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    SizedBox(height: 120, child: BoosterPack(booster: b, animate: false)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.isPremium ? l.boosterPremium : l.boosterStandard,
                            style: const TextStyle(fontFamily: kDisplayFont, fontSize: 20, fontWeight: FontWeight.w600)),
                        Text(l.boosterCards(b.nbCartes), style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          key: Key('shop-buy-${b.id}'),
                          onPressed: testMode || coins >= b.prixPieces ? () => _buy(context, ref, b, testMode) : null,
                          icon: const Icon(Icons.toll, size: 18),
                          label: Text(testMode ? l.shopFreeTest : l.boosterPrice(b.prixPieces)),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        ),
                        if (!testMode && coins < b.prixPieces)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(l.boosterNotEnoughCoins, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
