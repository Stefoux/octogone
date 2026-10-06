import 'package:flutter/material.dart';

/// Traitement de la photo selon l'effet.
enum PhotoFilter { none, sepia, negative, noir }

/// Décorations dessinées en plus du shader.
enum Decoration2 { none, neon, cracks, confetti, goldPlate, museumPlaque }

/// Rendu d'un effet de carte : mode du shader holo, teinte, fusion, cadre…
@immutable
class EffectSpec {
  const EffectSpec({
    required this.mode,
    this.tint,
    this.tintStrength = 0.0,
    this.intensity = 1.0,
    this.blend = BlendMode.srcOver,
    this.animated = false,
    this.photo = PhotoFilter.none,
    this.decoration = Decoration2.none,
    this.frame,
  });

  /// Mode du shader holo.frag (voir l'en-tête du shader).
  final double mode;
  final Color? tint;
  final double tintStrength;
  final double intensity;
  final BlendMode blend;
  final bool animated;
  final PhotoFilter photo;
  final Decoration2 decoration;

  /// Cadre imposé par l'effet (sinon celui de l'édition).
  final List<Color>? frame;
}

const _gold = [Color(0xFF8C6418), Color(0xFFF5D27A), Color(0xFFB98A2C), Color(0xFFFFF0B8), Color(0xFF8C6418)];
const _steel = [Color(0xFF5B6470), Color(0xFFC9D1DB), Color(0xFF7B8592), Color(0xFFE8EDF3), Color(0xFF5B6470)];
const _black = [Color(0xFF050505), Color(0xFF1C1C1C), Color(0xFF050505), Color(0xFF2A2A2A), Color(0xFF050505)];
const _brass = [Color(0xFF5A4320), Color(0xFFC8A15C), Color(0xFF7C5E2C), Color(0xFFE2C68C), Color(0xFF5A4320)];
const _antique = [Color(0xFF3B2A16), Color(0xFFB08A4E), Color(0xFF5C4325), Color(0xFFD6B57A), Color(0xFF3B2A16)];

Color? _hex(String? hex) {
  if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

/// Effet visuel d'une variante (clé `variants.effet` + teinte `variants.couleur`).
EffectSpec effectFor(String effet, {String? couleur, String frameFamily = 'original'}) {
  final tint = _hex(couleur);
  switch (effet) {
    case 'base':
      return EffectSpec(mode: 11, intensity: frameFamily == 'chrome' ? 1.0 : 0.6, blend: BlendMode.screen);
    case 'refractor':
      return EffectSpec(mode: 0, tint: tint, tintStrength: tint == null ? 0 : 0.6, blend: BlendMode.screen);
    case 'x_fractor':
      return const EffectSpec(mode: 1, blend: BlendMode.screen);
    case 'prism':
      return const EffectSpec(mode: 2, blend: BlendMode.screen);
    case 'speckle':
      return const EffectSpec(mode: 3, blend: BlendMode.screen);
    case 'wave':
      return EffectSpec(mode: 4, tint: tint, tintStrength: 0.6, blend: BlendMode.screen);
    case 'superfractor':
      return const EffectSpec(mode: 5, blend: BlendMode.screen, animated: true, frame: _gold);
    case 'sepia':
      return EffectSpec(mode: 0, tint: tint ?? const Color(0xFFB08A5A), tintStrength: 0.8,
          blend: BlendMode.screen, photo: PhotoFilter.sepia);
    case 'negative':
      return const EffectSpec(mode: 0, intensity: 0.7, blend: BlendMode.screen, photo: PhotoFilter.negative);
    // --- raretés originales ---
    case 'acier':
      return const EffectSpec(mode: 6, blend: BlendMode.screen, frame: _steel);
    case 'neon':
      return const EffectSpec(mode: 13, decoration: Decoration2.neon, animated: true);
    case 'face_a_face':
      return const EffectSpec(mode: 13, decoration: Decoration2.neon, animated: true, intensity: 0.8);
    case 'cicatrice':
      return const EffectSpec(mode: 11, blend: BlendMode.screen, decoration: Decoration2.cracks);
    case 'onde_de_choc':
      return const EffectSpec(mode: 8, blend: BlendMode.screen, animated: true);
    case 'cle_fatale':
      return const EffectSpec(mode: 12, animated: true);
    case 'main_levee':
      return const EffectSpec(mode: 10, intensity: 0.6, blend: BlendMode.screen,
          decoration: Decoration2.confetti, animated: true, frame: _gold);
    case 'ceinture_or':
      return const EffectSpec(mode: 10, blend: BlendMode.screen, decoration: Decoration2.goldPlate, frame: _gold);
    case 'heritage':
      return const EffectSpec(mode: 10, intensity: 0.7, blend: BlendMode.screen,
          photo: PhotoFilter.sepia, frame: _antique);
    case 'moment':
      return const EffectSpec(mode: 10, intensity: 0.45, blend: BlendMode.screen,
          decoration: Decoration2.museumPlaque, frame: _brass);
    case 'trilogie':
      return const EffectSpec(mode: 2, blend: BlendMode.screen, frame: _gold, intensity: 0.55);
    // --- cartes Tactique (mêmes rendus que les raretés originales) ---
    case 'tactique_peu_commune':
      return effectFor('acier');
    case 'tactique_rare':
      return effectFor('neon');
    case 'tactique_epique':
      return effectFor('onde_de_choc');
    case 'tactique_legendaire':
      return effectFor('superfractor');
    case 'octogone_noir':
      return const EffectSpec(mode: 9, blend: BlendMode.screen, animated: true, photo: PhotoFilter.noir, frame: _black);
    default:
      return EffectSpec(mode: 0, tint: tint, tintStrength: tint == null ? 0 : 0.6, blend: BlendMode.screen);
  }
}

/// Matrices de couleur pour les filtres photo.
ColorFilter? photoFilter(PhotoFilter f) => switch (f) {
      PhotoFilter.none => null,
      PhotoFilter.sepia => const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0, //
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]),
      PhotoFilter.negative => const ColorFilter.matrix([
          -1, 0, 0, 0, 255, //
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
      PhotoFilter.noir => const ColorFilter.matrix([
          0.22, 0.45, 0.08, 0, -18, //
          0.22, 0.45, 0.08, 0, -18,
          0.22, 0.45, 0.08, 0, -18,
          0, 0, 0, 1, 0,
        ]),
    };

/// Cadre par défaut d'une famille d'édition.
List<Color> frameColors(String family) => switch (family) {
      'chrome' => const [Color(0xFF6B7480), Color(0xFFE4E8EE), Color(0xFF8A94A3), Color(0xFFF4F6F9), Color(0xFF6B7480)],
      'tactique' => const [Color(0xFF1B2333), Color(0xFF55627A), Color(0xFF232C40), Color(0xFF6B7891), Color(0xFF1B2333)],
      'papier' => const [Color(0xFFD9CDB2), Color(0xFFF2EAD8), Color(0xFFD9CDB2), Color(0xFFF2EAD8), Color(0xFFD9CDB2)],
      _ => const [Color(0xFF14161C), Color(0xFF2E3240), Color(0xFF14161C), Color(0xFF353A4A), Color(0xFF14161C)],
    };
