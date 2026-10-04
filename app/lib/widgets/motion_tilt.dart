import 'package:flutter/material.dart';

import 'tilt_builder.dart';

/// Inclinaison -1..1 combinant l'orientation du téléphone (accéléromètre) et
/// le pointeur : la souris sur ordinateur, le doigt qui glisse sur mobile.
/// Le pointeur est prioritaire ; au relâchement on revient doucement au
/// capteur. (Une app native lit les capteurs de mouvement sans permission,
/// contrairement à Safari : pas de demande à faire sur iOS.)
class MotionTiltBuilder extends StatefulWidget {
  const MotionTiltBuilder({super.key, required this.builder, this.useSensors = true});

  final Widget Function(BuildContext context, Offset tilt) builder;
  final bool useSensors;

  @override
  State<MotionTiltBuilder> createState() => _MotionTiltBuilderState();
}

class _MotionTiltBuilderState extends State<MotionTiltBuilder> with SingleTickerProviderStateMixin {
  Offset? _pointer;
  Offset _releaseFrom = Offset.zero;
  late final AnimationController _release = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _release.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    if (size.isEmpty) return;
    final p = Offset(
      ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );
    _release.stop();
    setState(() => _pointer = p);
  }

  void _leave() {
    if (_pointer == null) return;
    _releaseFrom = _pointer!;
    _pointer = null;
    _release.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        return MouseRegion(
          onHover: (e) => _track(e.localPosition, size),
          onExit: (_) => _leave(),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (e) => _track(e.localPosition, size),
            onPointerUp: (_) => _leave(),
            onPointerCancel: (_) => _leave(),
            child: TiltBuilder(
              useSensors: widget.useSensors,
              builder: (context, sensor) {
                final Offset tilt;
                if (_pointer != null) {
                  tilt = _pointer!;
                } else if (_release.isAnimating) {
                  tilt = Offset.lerp(_releaseFrom, sensor, Curves.easeOut.transform(_release.value))!;
                } else {
                  tilt = sensor;
                }
                return widget.builder(context, tilt);
              },
            ),
          ),
        );
      },
    );
  }
}
