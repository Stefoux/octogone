import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../data/repositories/content_providers.dart';
import '../auth/auth_providers.dart';

/// Version affichée (à garder alignée sur app/pubspec.yaml).
const appVersion = '0.2.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final sync = ref.watch(syncControllerProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(l.account),
                subtitle: Text(session?.user.email ?? '—'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(l.syncContent),
                subtitle: Text(sync.error != null ? l.syncFailed : l.syncContentSub),
                trailing: sync.running ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                onTap: sync.running ? null : () => ref.read(syncControllerProvider.notifier).sync(),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(l.signOut),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
          ),
          const SizedBox(height: 24),
          Center(child: Text(l.versionLabel(appVersion), style: const TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }
}
