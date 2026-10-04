import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../data/repositories/content_providers.dart';
import '../domain/models.dart';

/// Drapeau en emoji (indicateurs régionaux) : aucun fichier image à fournir.
String flagEmoji(String? iso) {
  if (iso == null || iso.length != 2) return '🏳️';
  final base = 0x1F1E6 - 'A'.codeUnitAt(0);
  return String.fromCharCodes(iso.toUpperCase().codeUnits.map((c) => base + c));
}

/// Portrait cadré sur le visage (point focal calculé à l'import), avec une
/// silhouette originale si aucune image n'est disponible.
class FighterPortrait extends ConsumerWidget {
  const FighterPortrait({super.key, required this.imageId, this.borderRadius = 12, this.fit = BoxFit.cover});

  final String? imageId;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(imagesProvider).value ?? const {};
    final img = imageId == null ? null : images[imageId];
    final child = img == null
        ? const Silhouette()
        : CachedNetworkImage(
            imageUrl: AppConfig.publicImageUrl(img.storagePath),
            fit: fit,
            alignment: Alignment((img.focalX ?? 0.5) * 2 - 1, (img.focalY ?? 0.35) * 2 - 1),
            placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceHigh),
            errorWidget: (_, _, _) => const Silhouette(),
            fadeInDuration: const Duration(milliseconds: 200),
          );
    return ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: child);
  }
}

class Silhouette extends StatelessWidget {
  const Silhouette({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceHigh,
      child: CustomPaint(painter: _SilhouettePainter(), child: SizedBox.expand()),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF2E323D);
    final w = size.width, h = size.height;
    // Tête
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .5, h * .33), width: w * .32, height: h * .30), p);
    // Épaules / buste
    final body = Path()
      ..moveTo(w * .12, h)
      ..quadraticBezierTo(w * .14, h * .58, w * .5, h * .55)
      ..quadraticBezierTo(w * .86, h * .58, w * .88, h)
      ..close();
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Barre de stat 0-99.
class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.label, required this.value, this.estimated = false});
  final String label;
  final int value;
  final bool estimated;

  Color get _color => value >= 85
      ? AppColors.gold
      : value >= 70
          ? AppColors.success
          : value >= 55
              ? AppColors.steel
              : AppColors.crimson;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 99,
                minHeight: 8,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation(_color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(estimated ? '~$value' : '$value',
                textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class OverallBadge extends StatelessWidget {
  const OverallBadge({super.key, required this.value, this.size = 40});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
        color: AppColors.background,
      ),
      child: Text('$value', style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * .38)),
    );
  }
}

/// Bandeau « À vérifier » : la donnée n'a pas été confirmée par une source.
class ToVerifyBanner extends StatelessWidget {
  const ToVerifyBanner({super.key, required this.fields});
  final List<String> fields;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('À vérifier : ${fields.join(', ')}', style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Raccourci : vrai combattant à partir de son id (null si absent du cache).
Fighter? fighterById(WidgetRef ref, String id) =>
    ref.watch(fightersProvider).value?.where((f) => f.id == id).firstOrNull;
