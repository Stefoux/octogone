import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

/// Mini-jeux de soumission, à tour de rôle : le joueur qui attaque vise une
/// zone au bon moment (3 fois), celui qui se défend tape le plus vite
/// possible. Renvoie la réussite (0..1).
Future<double> showSubmissionGame(BuildContext context, {required bool attacking, required int seed}) async {
  final r = await showGeneralDialog<double>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    pageBuilder: (_, _, _) => attacking ? TimingGame(seed: seed) : const MashGame(),
  );
  return r ?? 0;
}

/// Attaque : un curseur va et vient, toucher quand il est dans la zone verte.
class TimingGame extends StatefulWidget {
  const TimingGame({super.key, required this.seed, this.taps = 3});
  final int seed;
  final int taps;

  @override
  State<TimingGame> createState() => _TimingGameState();
}

class _TimingGameState extends State<TimingGame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
    ..repeat(reverse: true);
  late final math.Random _rng = math.Random(widget.seed);
  late double _center = _newCenter();
  static const _half = 0.11;
  final _scores = <double>[];
  Timer? _limit;

  double _newCenter() => 0.25 + _rng.nextDouble() * 0.5;

  @override
  void initState() {
    super.initState();
    _limit = Timer(const Duration(seconds: 9), _finish);
  }

  @override
  void dispose() {
    _limit?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    if (_scores.length >= widget.taps) return;
    final d = (_c.value - _center).abs();
    final s = (1 - d / (_half * 2)).clamp(0.0, 1.0);
    HapticFeedback.mediumImpact();
    setState(() {
      _scores.add(s);
      _center = _newCenter();
    });
    if (_scores.length >= widget.taps) Future.delayed(const Duration(milliseconds: 350), _finish);
  }

  void _finish() {
    if (!mounted) return;
    _limit?.cancel();
    final total = _scores.fold<double>(0, (a, b) => a + b);
    Navigator.of(context).pop(total / widget.taps);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        key: const Key('sub-timing'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tap(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.subAttackTitle.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.subAttackHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 44,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final w = box.maxWidth;
                      return AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) => Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.outline),
                              ),
                            ),
                            Positioned(
                              left: (_center - _half) * w,
                              width: _half * 2 * w,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            Positioned(
                              left: _c.value * (w - 6),
                              width: 6,
                              top: -4,
                              bottom: -4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: const [BoxShadow(color: Colors.white70, blurRadius: 8)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.taps; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _scores.length
                              ? Color.lerp(AppColors.crimson, AppColors.success, _scores[i])
                              : AppColors.surfaceHigh,
                          border: Border.all(color: AppColors.outline),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Défense : taper le plus vite possible pendant 3,5 s.
class MashGame extends StatefulWidget {
  const MashGame({super.key, this.duration = const Duration(milliseconds: 3500), this.target = 24});
  final Duration duration;

  /// Nombre d'appuis pour une défense parfaite.
  final int target;

  @override
  State<MashGame> createState() => _MashGameState();
}

class _MashGameState extends State<MashGame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..forward()
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  int _taps = 0;
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop((_taps / widget.target).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        key: const Key('sub-mash'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (_done) return;
          HapticFeedback.selectionClick();
          setState(() => _taps++);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.subDefendTitle.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.crimson,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.subDefendHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                AnimatedScale(
                  scale: 1 + (_taps % 2) * 0.06,
                  duration: const Duration(milliseconds: 60),
                  child: Container(
                    width: 150,
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.crimson.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.crimson, width: 3),
                    ),
                    child: Text(
                      '$_taps',
                      style: const TextStyle(fontFamily: kDisplayFont, fontSize: 52, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 1 - _c.value,
                      minHeight: 10,
                      color: AppColors.gold,
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_taps / widget.target).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: AppColors.success,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
