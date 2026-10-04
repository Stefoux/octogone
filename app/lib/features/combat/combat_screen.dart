import 'package:flutter/material.dart';

import '../../core/theme.dart';

class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Combat')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_mma, size: 64, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text('Le combat tactique arrive en phase 4.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
