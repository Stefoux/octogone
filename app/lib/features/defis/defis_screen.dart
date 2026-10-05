import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import 'defis_service.dart';

/// Défis du jour et de la semaine : progression, récompenses à récupérer.
class DefisScreen extends ConsumerStatefulWidget {
  const DefisScreen({super.key});

  @override
  ConsumerState<DefisScreen> createState() => _DefisScreenState();
}

class _DefisScreenState extends ConsumerState<DefisScreen> {
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    // Toujours à jour en ouvrant l'écran (renouvellement à minuit)
    Future.microtask(() => ref.invalidate(defisProvider));
  }

  Future<void> _claim(Defi d) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(d.id));
    try {
      await ref.read(defisServiceProvider).claim(d.id);
      unawaited(HapticFeedback.mediumImpact());
      messenger.showSnackBar(SnackBar(content: Text(l.defisClaimedSnack(d.pieces))));
    } on DefiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(switch (e.kind) {
          DefiError.alreadyClaimed => l.defisErrAlready,
          DefiError.notDone => l.defisErrNotDone,
          DefiError.other => l.errorWithMessage(e.message ?? ''),
        }),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
    } finally {
      ref.invalidate(defisProvider);
      if (mounted) setState(() => _busy.remove(d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(defisProvider);
    final defis = async.value ?? const <Defi>[];
    final daily = defis.where((d) => d.daily).toList();
    final weekly = defis.where((d) => !d.daily).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.defisTitle)),
      body: async.hasError && defis.isEmpty
          ? Center(child: Text(l.defisError, style: const TextStyle(color: AppColors.textMuted)))
          : async.isLoading && defis.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(defisProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      if (daily.isNotEmpty) ...[
                        _Header(title: l.defisToday, end: daily.first.fin),
                        for (final (i, d) in daily.indexed)
                          _DefiTile(defi: d, busy: _busy.contains(d.id), onClaim: () => _claim(d))
                              .animate(delay: (50 * i).ms)
                              .fadeIn(duration: Motion.medium)
                              .slideY(begin: 0.15, end: 0),
                      ],
                      if (weekly.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _Header(title: l.defisWeek, end: weekly.first.fin),
                        for (final d in weekly) _DefiTile(defi: d, busy: _busy.contains(d.id), onClaim: () => _claim(d)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.end});
  final String title;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final left = end.difference(DateTime.now());
    final time = left.inHours >= 24
        ? l.durationDh(left.inDays, left.inHours.remainder(24))
        : l.durationHm(left.inHours.clamp(0, 23), left.inMinutes.remainder(60).clamp(0, 59));
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.85), letterSpacing: 2.5, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Icon(Icons.schedule, size: 14, color: AppColors.textMuted.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(l.defisRenewIn(time),
              overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ),
      ]),
    );
  }
}

class _DefiTile extends StatelessWidget {
  const _DefiTile({required this.defi, required this.busy, required this.onClaim});
  final Defi defi;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = defi;
    final ratio = (d.progression / d.objectif).clamp(0.0, 1.0);
    final Widget action;
    if (d.recupere) {
      action = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        const SizedBox(width: 4),
        Text(l.defisClaimed, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
      ]);
    } else if (d.claimable) {
      action = FilledButton(
        key: Key('defi-claim-${d.id}'),
        onPressed: busy ? null : onClaim,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
        child: Text(l.defisClaim),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.05, duration: 700.ms);
    } else {
      action = Text('${d.progression}/${d.objectif}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(d.title(context.lang),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        color: d.recupere ? AppColors.textMuted : AppColors.text,
                        decoration: d.recupere ? TextDecoration.lineThrough : null)),
              ),
              const SizedBox(width: 10),
              action,
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(d.done ? AppColors.gold : AppColors.steel),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.toll, size: 15, color: AppColors.gold),
              const SizedBox(width: 3),
              Text('+${d.pieces}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ),
    );
  }
}
