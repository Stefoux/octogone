import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profile.when(
            loading: () => Card(child: ListTile(title: Text(l.profileLoading))),
            error: (e, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off),
                title: Text(l.profileOffline),
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
                            Container(
                              width: 58,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF3A2E1A), AppColors.surfaceHigh],
                                ),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                              ),
                              child: Text(p.pseudo.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                      fontFamily: kDisplayFont, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.gold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.pseudo,
                                    style: const TextStyle(fontFamily: kDisplayFont, fontSize: 24, fontWeight: FontWeight.w600)),
                                if (p.isAdmin)
                                  Text(l.administrator, style: const TextStyle(color: AppColors.gold)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          Text(l.myFriendCode, style: const TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Row(children: [
                            SelectableText(p.friendCode,
                                style: const TextStyle(
                                    fontSize: 22,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [FontFeature.tabularFigures()])),
                            IconButton(
                              tooltip: l.copy,
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: p.friendCode));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(l.friendCodeCopied)));
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
                title: Text(l.settings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/reglages'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.creditsAndSources),
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
