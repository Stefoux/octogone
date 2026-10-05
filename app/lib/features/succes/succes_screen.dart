import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../defis/defis_service.dart' show DefiError, DefiException;
import 'succes_service.dart';

IconData _icon(String type) => switch (type) {
      'boosters_ouverts' => Icons.inventory_2_outlined,
      'cartes_distinctes' => Icons.style_outlined,
      'legendaires' => Icons.workspace_premium_outlined,
      'mythiques' => Icons.diamond_outlined,
      'series_completes' => Icons.collections_bookmark_outlined,
      'vitrine' => Icons.auto_awesome_mosaic_outlined,
      'doublons_recycles' => Icons.recycling,
      'cartes_fabriquees' => Icons.construction,
      'defis_recuperes' => Icons.flag_outlined,
      _ => Icons.emoji_events_outlined,
    };

/// Succès : objectifs permanents, débloqués selon ta collection.
class SuccesScreen extends ConsumerStatefulWidget {
  const SuccesScreen({super.key});

  @override
  ConsumerState<SuccesScreen> createState() => _SuccesScreenState();
}

class _SuccesScreenState extends ConsumerState<SuccesScreen> {
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(succesProvider));
  }

  Future<void> _claim(Succes s) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(s.id));
    try {
      await ref.read(succesServiceProvider).claim(s.id);
      unawaited(HapticFeedback.heavyImpact());
      messenger.showSnackBar(SnackBar(content: Text(l.defisClaimedSnack(s.pieces))));
    } on DefiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(switch (e.kind) {
          DefiError.alreadyClaimed => l.defisErrAlready,
          DefiError.notDone => l.succesErrNotDone,
          DefiError.other => l.errorWithMessage(e.message ?? ''),
        }),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
    } finally {
      ref.invalidate(succesProvider);
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(succesProvider);
    final list = async.value ?? const <Succes>[];
    final unlocked = list.where((s) => s.done).length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.succesTitle)),
      body: async.hasError && list.isEmpty
          ? Center(child: Text(l.succesError, style: const TextStyle(color: AppColors.textMuted)))
          : async.isLoading && list.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    Text(l.succesCount(unlocked, list.length),
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    for (final (i, s) in list.indexed)
                      _SuccesTile(succes: s, busy: _busy.contains(s.id), onClaim: () => _claim(s))
                          .animate(delay: (30 * i).ms)
                          .fadeIn(duration: Motion.medium),
                  ],
                ),
    );
  }
}

class _SuccesTile extends StatelessWidget {
  const _SuccesTile({required this.succes, required this.busy, required this.onClaim});
  final Succes succes;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = succes;
    final color = s.done ? AppColors.gold : AppColors.textMuted;
    final Widget trailing;
    if (s.recupere) {
      trailing = const Icon(Icons.check_circle, color: AppColors.success);
    } else if (s.claimable) {
      trailing = FilledButton(
        key: Key('succes-claim-${s.id}'),
        onPressed: busy ? null : onClaim,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
        child: Text(l.defisClaim),
      );
    } else {
      trailing = Text('${s.progression}/${s.objectif}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withValues(alpha: s.done ? 0.16 : 0.08),
                border: Border.all(color: color.withValues(alpha: s.done ? 0.6 : 0.2)),
              ),
              child: Icon(s.done ? _icon(s.type) : Icons.lock_outline, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title(context.lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (s.progression / s.objectif).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceHigh,
                        valueColor: AlwaysStoppedAnimation(s.done ? AppColors.gold : AppColors.steel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.toll, size: 14, color: AppColors.gold),
                  const SizedBox(width: 2),
                  Text('+${s.pieces}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            trailing,
          ]),
        ),
      ),
    );
  }
}

/// Entrée du Profil : nombre de succès débloqués et récompenses en attente.
class SuccesProfileTile extends ConsumerWidget {
  const SuccesProfileTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(succesProvider).value;
    final claimable = list?.where((s) => s.claimable).length ?? 0;
    return Card(
      child: ListTile(
        key: const Key('profile-succes'),
        leading: const Icon(Icons.emoji_events_outlined),
        title: Text(l.succesTitle),
        subtitle: list == null ? null : Text(l.succesCount(list.where((s) => s.done).length, list.length)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (claimable > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(10)),
              child: Text('$claimable', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          const Icon(Icons.chevron_right),
        ]),
        onTap: () => context.push('/succes'),
      ),
    );
  }
}
