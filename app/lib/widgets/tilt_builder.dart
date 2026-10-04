import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Fournit l'inclinaison du téléphone (-1..1 sur chaque axe) à partir de
/// l'accéléromètre, relative à la position de départ, lissée.
class TiltBuilder extends StatefulWidget {
  const TiltBuilder({super.key, required this.builder, this.useSensors = true});

  final Widget Function(BuildContext context, Offset tilt) builder;

  /// false dans les tests (pas de capteur).
  final bool useSensors;

  @override
  State<TiltBuilder> createState() => _TiltBuilderState();
}

class _TiltBuilderState extends State<TiltBuilder> {
  StreamSubscription<AccelerometerEvent>? _sub;
  Offset _tilt = Offset.zero;
  Offset? _baseline;
  final List<Offset> _calibration = [];

  @override
  void initState() {
    super.initState();
    if (!widget.useSensors) return;
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
        (e) {
          final raw = Offset(e.x, e.y);
          if (_baseline == null) {
            _calibration.add(raw);
            if (_calibration.length >= 8) {
              _baseline = _calibration.reduce((a, b) => a + b) / _calibration.length.toDouble();
            }
            return;
          }
          final d = raw - _baseline!;
          final target = Offset((-d.dx / 4).clamp(-1.0, 1.0), (d.dy / 4).clamp(-1.0, 1.0));
          final smoothed = Offset.lerp(_tilt, target, 0.15)!;
          if ((smoothed - _tilt).distance > 0.003 && mounted) setState(() => _tilt = smoothed);
        },
        onError: (Object _) {},
        cancelOnError: true,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _tilt);
}
