import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../auth/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profile.when(
            loading: () => const Card(child: ListTile(title: Text('Chargement du profil…'))),
            error: (e, _) => const Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off),
                title: Text('Profil indisponible hors ligne'),
              ),
            ),
            data: (p) => p == null
                ? const SizedBox.shrink()
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.surfaceHigh,
                              child: Text(p.pseudo.characters.first.toUpperCase(),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.pseudo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                if (p.isAdmin)
                                  const Text('Administrateur', style: TextStyle(color: AppColors.gold)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          const Text('Mon code ami', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Row(children: [
                            SelectableText(p.friendCode,
                                style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.w900)),
                            IconButton(
                              tooltip: 'Copier',
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: p.friendCode));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Code ami copié')));
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Réglages'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/reglages'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Crédits et sources'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/credits'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
