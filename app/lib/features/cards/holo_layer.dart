import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'effects.dart';

/// Programme GPU des effets holographiques (shaders/holo.frag), chargé une fois.
/// null si le shader n'est pas disponible (tests, appareil ancien) : la carte
/// s'affiche alors sans reflet.
final holoProgramProvider = FutureProvider<ui.FragmentProgram?>((ref) async {
  try {
    return await ui.FragmentProgram.fromAsset('shaders/holo.frag');
  } catch (_) {
    return null;
  }
});

/// Calque d'effet dessiné par-dessus la carte.
class HoloLayer extends ConsumerStatefulWidget {
  const HoloLayer({super.key, required this.spec, required this.tilt, this.animate = true});

  final EffectSpec spec;

  /// Inclinaison -1..1 (gyroscope/accéléromètre ou doigt).
  final Offset tilt;

  /// false pour les miniatures de l'album : image fixe, pas d'animation.
  final bool animate;

  @override
  ConsumerState<HoloLayer> createState() => _HoloLayerState();
}

class _HoloLayerState extends ConsumerState<HoloLayer> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _time = 0;
  ui.FragmentShader? _shader;
  ui.FragmentProgram? _program;

  bool get _needsTicker => widget.animate && widget.spec.animated;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant HoloLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (_needsTicker && _ticker == null) {
      _ticker = createTicker((elapsed) => setState(() => _time = elapsed.inMicroseconds / 1e6))..start();
    } else if (!_needsTicker && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(holoProgramProvider).value;
    if (program == null) return const SizedBox.expand();
    if (!identical(program, _program)) {
      _shader?.dispose();
      _program = program;
      _shader = program.fragmentShader();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HoloPainter(_shader!, widget.spec, widget.tilt, _time),
      ),
    );
  }
}

class _HoloPainter extends CustomPainter {
  _HoloPainter(this.shader, this.spec, this.tilt, this.time);

  final ui.FragmentShader shader;
  final EffectSpec spec;
  final Offset tilt;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final tint = spec.tint ?? Colors.white;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, tilt.dx.clamp(-1.0, 1.0))
      ..setFloat(3, tilt.dy.clamp(-1.0, 1.0))
      ..setFloat(4, time)
      ..setFloat(5, tint.r)
      ..setFloat(6, tint.g)
      ..setFloat(7, tint.b)
      ..setFloat(8, spec.tint == null ? 0 : spec.tintStrength)
      ..setFloat(9, spec.mode)
      ..setFloat(10, spec.intensity);
    canvas.drawRect(Offset.zero & size, Paint()
      ..shader = shader
      ..blendMode = spec.blend);
  }

  @override
  bool shouldRepaint(covariant _HoloPainter old) =>
      old.tilt != tilt || old.time != time || old.spec != spec || old.shader != shader;
}
