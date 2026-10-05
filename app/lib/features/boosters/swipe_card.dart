import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Carte qu'on fait passer d'un geste : elle suit le doigt, puis s'envole
/// dans la direction dominante du glissement, avec une animation propre à
/// chaque côté :
/// - gauche / droite : lancée en tournoyant ;
/// - haut : s'envole en tournant sur elle-même et rétrécit ;
/// - bas : tombe en basculant et s'efface.
///
/// La zone de geste couvre tout le widget ; seule [child] (la carte, centrée
/// à la taille [cardSize]) bouge. Si [canFling] est faux, le geste est freiné
/// et [onBlocked] est appelé (ex. : retourner une carte encore face cachée).
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.child,
    required this.cardSize,
    required this.onSwiped,
    this.canFling = true,
    this.onTap,
    this.onBlocked,
    this.onFlingStart,
  });

  final Widget child;
  final Size cardSize;
  final bool canFling;

  /// Appelé quand la carte a fini de s'envoler.
  final ValueChanged<AxisDirection> onSwiped;

  /// Appelé au début de l'envol (son, vibration).
  final ValueChanged<AxisDirection>? onFlingStart;
  final VoidCallback? onTap;
  final ValueChanged<AxisDirection>? onBlocked;

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late final AnimationController _back =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..addListener(_onBack);
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Offset _backFrom = Offset.zero;
  Offset _flyFrom = Offset.zero;
  AxisDirection? _dir;

  /// Distance (en pixels) ou vitesse (px/s) à partir de laquelle la carte part.
  static const _distance = 80.0;
  static const _velocity = 650.0;

  bool get flying => _dir != null;

  @override
  void dispose() {
    _back.dispose();
    _fly.dispose();
    super.dispose();
  }

  void _onBack() => setState(() => _drag = Offset.lerp(_backFrom, Offset.zero, Curves.elasticOut.transform(_back.value))!);

  /// Fait partir la carte par programme (ex. : un toucher sur une carte révélée).
  Future<void> fling(AxisDirection dir) async {
    if (flying) return;
    _back.stop();
    setState(() {
      _dir = dir;
      _flyFrom = _drag;
    });
    widget.onFlingStart?.call(dir);
    await _fly.forward(from: 0);
    if (mounted) widget.onSwiped(dir);
  }

  static AxisDirection _dominant(Offset v) => v.dx.abs() >= v.dy.abs()
      ? (v.dx < 0 ? AxisDirection.left : AxisDirection.right)
      : (v.dy < 0 ? AxisDirection.up : AxisDirection.down);

  void _onUpdate(DragUpdateDetails d) {
    if (flying) return;
    _back.stop();
    // Freiné quand la carte ne peut pas encore partir
    setState(() => _drag += d.delta * (widget.canFling ? 1 : 0.25));
  }

  void _onEnd(DragEndDetails d) {
    if (flying) return;
    final v = d.velocity.pixelsPerSecond;
    final moved = _drag.distance > _distance / (widget.canFling ? 1 : 4);
    final fast = v.distance > _velocity;
    if (moved || fast) {
      final dir = _dominant(fast && v.distance > _drag.distance * 4 ? v : _drag);
      if (widget.canFling) {
        fling(dir);
        return;
      }
      widget.onBlocked?.call(dir);
    }
    _backFrom = _drag;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: flying ? null : widget.onTap,
      onPanUpdate: _onUpdate,
      onPanEnd: _onEnd,
      child: LayoutBuilder(builder: (context, c) {
        return AnimatedBuilder(
          animation: _fly,
          child: SizedBox.fromSize(size: widget.cardSize, child: widget.child),
          builder: (context, child) => Center(
            child: Opacity(
              opacity: _opacity(),
              child: Transform(alignment: Alignment.center, transform: _transform(c.biggest), child: child),
            ),
          ),
        );
      }),
    );
  }

  double _opacity() {
    if (_dir == null) return 1;
    final t = _fly.value;
    return switch (_dir!) {
      AxisDirection.down => (1 - Curves.easeIn.transform(t) * 1.2).clamp(0.0, 1.0),
      AxisDirection.up => (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0),
      _ => (1 - math.max(0.0, t - 0.6) / 0.4).clamp(0.0, 1.0),
    };
  }

  Matrix4 _transform(Size area) {
    final w = math.max(area.width, 1.0);
    final h = math.max(area.height, 1.0);
    // Pendant le geste : la carte suit le doigt et s'incline
    final dragTilt = _drag.dx / w * 0.45;
    final m = Matrix4.identity()..setEntry(3, 2, 0.0012);
    if (_dir == null) {
      return m
        ..translateByDouble(_drag.dx, _drag.dy, 0, 1)
        ..rotateZ(dragTilt)
        ..rotateX(-_drag.dy / h * 0.6);
    }
    final t = _fly.value;
    final from = _flyFrom;
    switch (_dir!) {
      case AxisDirection.left:
      case AxisDirection.right:
        final s = _dir == AxisDirection.left ? -1.0 : 1.0;
        final e = Curves.easeInCubic.transform(t);
        return m
          ..translateByDouble(from.dx + s * w * 1.3 * e, from.dy - h * 0.08 * math.sin(t * math.pi) + from.dy * e, 0, 1)
          ..rotateZ(from.dx / w * 0.45 + s * 0.9 * e);
      case AxisDirection.up:
        final e = Curves.easeInCubic.transform(t);
        final sc = 1 - 0.55 * Curves.easeIn.transform(t);
        return m
          ..translateByDouble(from.dx * (1 - e), from.dy - h * 1.1 * e, 0, 1)
          ..rotateZ(2 * math.pi * 1.25 * Curves.easeInOut.transform(t))
          ..scaleByDouble(sc, sc, 1, 1);
      case AxisDirection.down:
        // Chute : accélération de la gravité, bascule vers l'avant
        final e = t * t;
        return m
          ..translateByDouble(from.dx, from.dy + h * 0.7 * e, 0, 1)
          ..rotateX(1.2 * e)
          ..rotateZ(from.dx / w * 0.45 * (1 + t))
          ..scaleByDouble(1 - 0.15 * t, 1 - 0.15 * t, 1, 1);
    }
  }
}
