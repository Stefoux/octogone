import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Octogone régulier centré sur [c], de rayon [r] (côtés plats en haut et en
/// bas, comme l'emblème des cartes).
Path octagonPath(Offset c, double r, {double rotation = 0}) {
  final p = Path();
  for (var i = 0; i < 8; i++) {
    final a = math.pi / 8 + i * math.pi / 4 + rotation;
    final pt = c + Offset(math.cos(a), math.sin(a)) * r;
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Découpe un widget en octogone.
class OctagonClipper extends CustomClipper<Path> {
  const OctagonClipper();

  @override
  Path getClip(Size size) => octagonPath(size.center(Offset.zero), size.shortestSide / 2);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
