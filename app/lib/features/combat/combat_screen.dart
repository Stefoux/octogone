import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.navFight)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_mma, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(l.fightComing, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
