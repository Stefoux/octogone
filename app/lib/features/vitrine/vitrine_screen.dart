import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../cards/card_view.dart';
import '../cards/trading_card.dart';
import '../collection/owned_card_picker.dart';
import 'vitrine_service.dart';

/// Ma vitrine : une place d'honneur et 8 emplacements. Toucher un emplacement
/// vide pour exposer une carte, appui long puis glisser pour réorganiser,
/// « Modifier » pour retirer des cartes.
class VitrineScreen extends ConsumerStatefulWidget {
  const VitrineScreen({super.key});

  @override
  ConsumerState<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends ConsumerState<VitrineScreen> {
  bool _editing = false;

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.vitrineSaveError('$e'))));
    }
  }

  Future<void> _pick(int slot, List<String?> slots) async {
    final l = context.l10n;
    final picked = await pickOwnedCard(context, title: l.vitrinePickTitle, exclude: {...slots.nonNulls});
    if (picked == null || !mounted) return;
    unawaited(HapticFeedback.lightImpact());
    await _guard(() => ref.read(vitrineProvider.notifier).add(picked.id, slot: slot));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(vitrineProvider);
    final slots = async.value ?? List<String?>.filled(kVitrineSlots, null);
    final owned = {for (final o in ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[]) o.id: o};
    final filled = slots.nonNulls.length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l.vitrineTitle),
        actions: [
          if (filled > 0)
            TextButton(
              key: const Key('vitrine-edit'),
              onPressed: () => setState(() => _editing = !_editing),
              child: Text(_editing ? l.vitrineDone : l.vitrineEdit),
            ),
        ],
      ),
      body: async.isLoading && async.value == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(builder: (context, c) {
              final honorW = math.min(c.maxWidth * 0.5, 230.0);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  Text(
                    filled == 0 ? l.vitrineEmpty : l.vitrineReorderHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                  ),
                  const SizedBox(height: 18),
                  Text(l.vitrineHonor.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold.withValues(alpha: 0.85))),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: honorW,
                      child: _Slot(
                        index: 0,
                        owned: owned[slots[0]],
                        editing: _editing,
                        honor: true,
                        onPick: () => _pick(0, slots),
                        onRemove: (id) => _guard(() => ref.read(vitrineProvider.notifier).remove(id)),
                        onSwap: (a, b) => _guard(() => ref.read(vitrineProvider.notifier).swap(a, b)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: c.maxWidth > 600 ? 8 : 4,
                    mainAxisSpacing: 22,
                    crossAxisSpacing: 10,
                    childAspectRatio: kCardAspect * 0.92,
                    children: [
                      for (var i = 1; i < kVitrineSlots; i++)
                        _Slot(
                          index: i,
                          owned: owned[slots[i]],
                          editing: _editing,
                          onPick: () => _pick(i, slots),
                          onRemove: (id) => _guard(() => ref.read(vitrineProvider.notifier).remove(id)),
                          onSwap: (a, b) => _guard(() => ref.read(vitrineProvider.notifier).swap(a, b)),
                        ),
                    ],
                  ),
                ],
              );
            }),
    );
  }
}

class _Slot extends ConsumerWidget {
  const _Slot({
    required this.index,
    required this.owned,
    required this.editing,
    required this.onPick,
    required this.onRemove,
    required this.onSwap,
    this.honor = false,
  });

  final int index;
  final OwnedCard? owned;
  final bool editing;
  final bool honor;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;
  final void Function(int from, int to) onSwap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = owned == null ? null : buildCardView(ref, cardId: owned!.cardId, owned: owned);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) {
        HapticFeedback.selectionClick();
        onSwap(d.data, index);
      },
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final Widget content;
        if (view == null) {
          content = _EmptySlot(key: Key('vitrine-slot-$index'), onTap: onPick, highlight: hovering, honor: honor);
        } else {
          final card = Showcased(
            rarete: view.variant.rarete,
            honor: honor,
            child: TradingCard(view: view, animate: honor),
          );
          content = LongPressDraggable<int>(
            key: Key('vitrine-slot-$index'),
            data: index,
            hapticFeedbackOnStart: true,
            feedback: SizedBox(
              width: honor ? 180 : 96,
              child: Opacity(opacity: 0.9, child: TradingCard(view: view, animate: false)),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: TradingCard(view: view, animate: false)),
            child: GestureDetector(
              onTap: editing ? null : () => context.push('/carte/${Uri.encodeComponent(view.card!.id)}?owned=${owned!.id}'),
              child: Stack(clipBehavior: Clip.none, children: [
                card,
                if (editing)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Material(
                      color: AppColors.crimson,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: Key('vitrine-remove-$index'),
                        customBorder: const CircleBorder(),
                        onTap: () => onRemove(owned!.id),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16)),
                      ),
                    ),
                  ),
              ]),
            ),
          );
        }
        return AnimatedScale(
          scale: hovering ? 1.06 : 1,
          duration: Motion.fast,
          child: AspectRatio(aspectRatio: kCardAspect, child: content),
        );
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({super.key, required this.onTap, required this.highlight, required this.honor});
  final VoidCallback onTap;
  final bool highlight;
  final bool honor;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.gold : AppColors.gold.withValues(alpha: honor ? 0.5 : 0.3);
    return InkWell(
      borderRadius: BorderRadius.circular(honor ? 14 : 8),
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorder(color: color, radius: honor ? 14 : 8),
        child: Center(child: Icon(Icons.add, color: color, size: honor ? 40 : 24)),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
        Paint()..color = color.withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color;
}

/// Mise en valeur d'une carte exposée : halo et socle lumineux de la couleur
/// de sa rareté (plus intenses pour les rares), liseré doré animé pour les
/// Légendaires et Mythiques.
class Showcased extends StatefulWidget {
  const Showcased({super.key, required this.rarete, required this.child, this.honor = false});
  final String rarete;
  final Widget child;
  final bool honor;

  @override
  State<Showcased> createState() => _ShowcasedState();
}

class _ShowcasedState extends State<Showcased> with SingleTickerProviderStateMixin {
  late final AnimationController _rim = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  int get _rank => Rarity.fromKey(widget.rarete).index;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_rank >= 4 && !reduce) {
      if (!_rim.isAnimating) _rim.repeat();
    } else {
      _rim.stop();
    }
  }

  @override
  void dispose() {
    _rim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarity[widget.rarete] ?? AppColors.steel;
    final k = const [0.0, 0.25, 0.5, 0.7, 0.9, 1.0][_rank.clamp(0, 5)];
    return Stack(clipBehavior: Clip.none, children: [
      // Socle lumineux sous la carte
      if (k > 0)
        Positioned(
          left: -12,
          right: -12,
          bottom: -14,
          height: 26,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [color.withValues(alpha: 0.55 * k), color.withValues(alpha: 0)]),
              ),
            ),
          ),
        ),
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.honor ? 14 : 8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 12, offset: const Offset(0, 8)),
            if (k > 0) BoxShadow(color: color.withValues(alpha: 0.45 * k), blurRadius: 18 + 18 * k, spreadRadius: k * 2),
          ],
        ),
        child: widget.child,
      ),
      if (_rank >= 4)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _rim,
              builder: (context, _) =>
                  CustomPaint(painter: _RimPainter(_rim.value, color, widget.honor ? 14 : 8)),
            ),
          ),
        ),
    ]);
  }
}

class _RimPainter extends CustomPainter {
  _RimPainter(this.t, this.color, this.radius);
  final double t;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          transform: GradientRotation(t * 2 * math.pi),
          colors: [
            color.withValues(alpha: 0),
            const Color(0xFFFFF0B8),
            color,
            color.withValues(alpha: 0),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.08, 0.16, 0.3, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RimPainter old) => old.t != t || old.color != color;
}

/// Aperçu de la vitrine (profil) : place d'honneur et les suivantes en petit.
class VitrinePreview extends ConsumerWidget {
  const VitrinePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final slots = ref.watch(vitrineProvider).value ?? List<String?>.filled(kVitrineSlots, null);
    final owned = {for (final o in ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[]) o.id: o};
    final views = [
      for (final id in slots.nonNulls)
        if (owned[id] != null) buildCardView(ref, cardId: owned[id]!.cardId, owned: owned[id]),
    ].nonNulls.take(5).toList();
    return Card(
      child: InkWell(
        key: const Key('profile-vitrine'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/vitrine'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome_mosaic_outlined, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(child: Text(l.vitrineTitle, style: Theme.of(context).textTheme.titleLarge)),
              Text(l.vitrineCount(slots.nonNulls.length, kVitrineSlots),
                  style: const TextStyle(color: AppColors.textMuted, fontFeatures: [FontFeature.tabularFigures()])),
              const Icon(Icons.chevron_right),
            ]),
            const SizedBox(height: 12),
            if (views.isEmpty)
              Text(l.vitrineSubtitle, style: const TextStyle(color: AppColors.textMuted))
            else
              SizedBox(
                height: 112,
                child: Row(children: [
                  for (final (i, v) in views.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    SizedBox(
                      width: i == 0 ? 80 : 62,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Showcased(rarete: v.variant.rarete, child: TradingCard(view: v, animate: false)),
                      ),
                    ),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Bouton de la fiche carte : exposer cet exemplaire (ou le meilleur
/// exemplaire possédé) dans la vitrine, ou l'en retirer.
class VitrineToggleButton extends ConsumerWidget {
  const VitrineToggleButton({super.key, required this.cardId, this.ownedId});
  final String cardId;
  final String? ownedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final copies = ref.watch(ownedByCardProvider)[cardId] ?? const <OwnedCard>[];
    if (copies.isEmpty) return const SizedBox.shrink();
    final slots = ref.watch(vitrineProvider).value ?? const <String?>[];
    final exposed = copies.firstWhereOrNull((o) => slots.contains(o.id));
    final variants = ref.watch(allVariantsProvider).value ?? const <String, Variant>{};
    final target = copies.firstWhereOrNull((o) => o.id == ownedId) ??
        copies.sortedBy<num>((o) => Rarity.fromKey(variants[o.variantId]?.rarete ?? 'commune').index).last;
    final messenger = ScaffoldMessenger.of(context);
    Future<void> run(Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(l.vitrineSaveError('$e'))));
      }
    }

    return OutlinedButton.icon(
      key: const Key('vitrine-toggle'),
      onPressed: () => run(() async {
        final notifier = ref.read(vitrineProvider.notifier);
        if (exposed != null) {
          await notifier.remove(exposed.id);
          messenger.showSnackBar(SnackBar(content: Text(l.vitrineRemoved)));
        } else if (await notifier.add(target.id)) {
          messenger.showSnackBar(SnackBar(content: Text(l.vitrineAdded)));
        } else {
          messenger.showSnackBar(SnackBar(content: Text(l.vitrineFull)));
        }
      }),
      icon: Icon(exposed != null ? Icons.remove_circle_outline : Icons.auto_awesome_mosaic_outlined, size: 18),
      label: Text(exposed != null ? l.vitrineRemove : l.vitrineAdd),
    );
  }
}

