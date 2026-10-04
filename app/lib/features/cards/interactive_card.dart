import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'card_back.dart';
import 'card_view.dart';
import 'trading_card.dart';

/// Carte en 3D : se retourne au toucher, s'incline avec le téléphone
/// (accéléromètre de sensors_plus) ou sous le doigt. L'inclinaison pilote
/// aussi les reflets holographiques.
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({super.key, required this.view, this.useSensors = true});

  final CardView view;

  /// false dans les tests (pas de capteurs) : inclinaison au doigt seulement.
  final bool useSensors;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> with TickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final AnimationController _settle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  StreamSubscription<AccelerometerEvent>? _sub;

  Offset _sensorTilt = Offset.zero;
  Offset? _dragTilt;
  Offset _settleFrom = Offset.zero;
  Offset? _baseline;
  final List<Offset> _calibration = [];

  @override
  void initState() {
    super.initState();
    _settle.addListener(() => setState(() {}));
    if (widget.useSensors) {
      try {
        _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
          _onAccel,
          onError: (Object _) {},
          cancelOnError: true,
        );
      } catch (_) {
        // Pas de capteur (émulateur sans capteur, ordinateur) : inclinaison au doigt.
      }
    }
  }

  void _onAccel(AccelerometerEvent e) {
    final raw = Offset(e.x, e.y);
    if (_baseline == null) {
      // Position de référence : la façon dont le téléphone est tenu au départ.
      _calibration.add(raw);
      if (_calibration.length >= 8) {
        _baseline = _calibration.reduce((a, b) => a + b) / _calibration.length.toDouble();
      }
      return;
    }
    final d = raw - _baseline!;
    final target = Offset((-d.dx / 4).clamp(-1.0, 1.0), (d.dy / 4).clamp(-1.0, 1.0));
    // Filtre passe-bas : mouvement doux, sans tremblement.
    final smoothed = Offset.lerp(_sensorTilt, target, 0.18)!;
    if ((smoothed - _sensorTilt).distance > 0.002 && mounted) setState(() => _sensorTilt = smoothed);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _flip.dispose();
    _settle.dispose();
    super.dispose();
  }

  Offset get _tilt {
    if (_dragTilt != null) return _dragTilt!;
    if (_settle.isAnimating) return Offset.lerp(_settleFrom, _sensorTilt, Curves.easeOut.transform(_settle.value))!;
    return _sensorTilt;
  }

  void _toggleFlip() {
    HapticFeedback.selectionClick();
    _flip.isCompleted || _flip.value > 0.5 ? _flip.reverse() : _flip.forward();
  }

  void _onPan(DragUpdateDetails d, Size size) {
    final local = d.localPosition;
    setState(() => _dragTilt = Offset(
          ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
          ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
        ));
  }

  void _endPan() {
    _settleFrom = _dragTilt ?? _sensorTilt;
    _dragTilt = null;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxWidth / kCardAspect);
      return GestureDetector(
        onTap: _toggleFlip,
        onPanUpdate: (d) => _onPan(d, size),
        onPanEnd: (_) => _endPan(),
        onPanCancel: _endPan,
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final angle = Curves.easeInOut.transform(_flip.value) * math.pi;
            final showBack = angle > math.pi / 2;
            final t = _tilt;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-t.dy * 0.2)
              ..rotateY(t.dx * 0.22 + angle);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: CardBack(view: widget.view),
                    )
                  : TradingCard(view: widget.view, tilt: t),
            );
          },
        ),
      );
    });
  }
}
