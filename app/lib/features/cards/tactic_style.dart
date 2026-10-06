import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// Pictogramme d'une carte Tactique (dessin original, pas de photo).
IconData tacticIcon(TacticKind k) => switch (k) {
  TacticKind.secondSouffle => Icons.air,
  TacticKind.coinDuCoach => Icons.medical_services,
  TacticKind.fouleEnDelire => Icons.campaign,
  TacticKind.machoireDAcier => Icons.shield,
  TacticKind.instinctDeTueur => Icons.local_fire_department,
  TacticKind.sortieDeCrise => Icons.directions_run,
  TacticKind.planDeMatch => Icons.track_changes,
  TacticKind.pressionTotale => Icons.compress,
};

/// Couleur d'accent d'une carte Tactique.
Color tacticColor(TacticKind k) => switch (k) {
  TacticKind.secondSouffle => const Color(0xFF3FB6E8),
  TacticKind.coinDuCoach => const Color(0xFF4CC38A),
  TacticKind.fouleEnDelire => const Color(0xFFE8B04A),
  TacticKind.machoireDAcier => const Color(0xFF9AA7B8),
  TacticKind.instinctDeTueur => const Color(0xFFE5484D),
  TacticKind.sortieDeCrise => const Color(0xFFB07CFF),
  TacticKind.planDeMatch => const Color(0xFF5B8CFF),
  TacticKind.pressionTotale => const Color(0xFFFF7A3D),
};
