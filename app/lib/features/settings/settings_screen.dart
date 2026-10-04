import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/content_providers.dart';
import '../auth/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final sync = ref.watch(syncControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Compte'),
                subtitle: Text(session?.user.email ?? '—'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Synchroniser le contenu'),
                subtitle: Text(sync.error != null ? 'Dernière tentative échouée (hors ligne ?)' : 'Combattants, éditions, images'),
                trailing: sync.running ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                onTap: sync.running ? null : () => ref.read(syncControllerProvider.notifier).sync(),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
          ),
          const SizedBox(height: 24),
          const Center(child: Text('Octogone · version 0.1.1 (phase 1)', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }
}
