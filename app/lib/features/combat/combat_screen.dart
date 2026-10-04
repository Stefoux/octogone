import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/octagon_emblem.dart';

class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.navFight)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OctagonEmblem(size: 128, child: Icon(Icons.sports_mma, size: 46, color: AppColors.gold)),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(l.fightComing,
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 15.5, height: 1.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
