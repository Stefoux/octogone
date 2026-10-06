import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../data/sync/content_sync.dart';
import '../../domain/models.dart';
import '../auth/auth_providers.dart';
import '../cards/card_view.dart';
import '../cards/trading_card.dart';

/// Réclame le pack de bienvenue (fonction serveur claim_welcome_pack) puis
/// met à jour la copie locale des cartes possédées.
Future<List<OwnedCard>> claimWelcomePack(WidgetRef ref) async {
  final client = ref.read(supabaseProvider);
  final rows = await client.rpc<List<dynamic>>('claim_welcome_pack');
  await ContentSync(ref.read(databaseProvider), client).syncOwnedCards();
  ref.invalidate(profileProvider);
  return [for (final r in rows) OwnedCard((r as Map).cast<String, dynamic>())];
}

/// Réclame les 3 cartes Tactique de départ (fonction serveur
/// recevoir_tactiques_depart), puis met à jour la copie locale.
Future<List<OwnedCard>> claimTacticStarter(WidgetRef ref) async {
  final client = ref.read(supabaseProvider);
  final rows = await client.rpc<List<dynamic>>('recevoir_tactiques_depart');
  await ContentSync(ref.read(databaseProvider), client).syncOwnedCards();
  ref.invalidate(profileProvider);
  return [for (final r in rows) OwnedCard((r as Map).cast<String, dynamic>())];
}

/// Carte d'accueil « Cartes Tactique offertes » (tant qu'elles n'ont pas été reçues).
class TacticStarterCard extends ConsumerStatefulWidget {
  const TacticStarterCard({super.key});

  @override
  ConsumerState<TacticStarterCard> createState() => _TacticStarterCardState();
}

class _TacticStarterCardState extends ConsumerState<TacticStarterCard> {
  bool _busy = false;

  Future<void> _open() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final cards = await claimTacticStarter(ref);
      if (!mounted) return;
      unawaited(HapticFeedback.heavyImpact());
      await showDialog<void>(context: context, builder: (_) => _RevealDialog(cards: cards, title: l.tacticCardsTitle));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'P0001' => l.tacticStarterAlready,
        'P0003' => l.tacticStarterUnavailable,
        _ => l.errorWithMessage(e.message),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.invalidate(profileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _GiftTile(
      icon: Icons.style,
      title: l.tacticStarter,
      subtitle: l.tacticStarterSub,
      busy: _busy,
      onOpen: _open,
    );
  }
}

/// Carte d'accueil « Pack de bienvenue » (tant qu'il n'a pas été ouvert).
class WelcomePackCard extends ConsumerStatefulWidget {
  const WelcomePackCard({super.key});

  @override
  ConsumerState<WelcomePackCard> createState() => _WelcomePackCardState();
}

class _WelcomePackCardState extends ConsumerState<WelcomePackCard> {
  bool _busy = false;

  Future<void> _open() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final cards = await claimWelcomePack(ref);
      if (!mounted) return;
      unawaited(HapticFeedback.heavyImpact());
      await showDialog<void>(context: context, builder: (_) => _RevealDialog(cards: cards));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'P0001' ? l.welcomePackAlready : l.errorWithMessage(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.invalidate(profileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _GiftTile(
      icon: Icons.card_giftcard,
      title: l.welcomePack,
      subtitle: l.welcomePackSub,
      busy: _busy,
      onOpen: _open,
    );
  }
}

/// Bandeau cadeau de l'accueil (pack de bienvenue, cartes Tactique offertes).
class _GiftTile extends StatelessWidget {
  const _GiftTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onOpen,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x33E8B04A), Color(0x11D7263D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Icon(icon, color: AppColors.gold, size: 34)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.12, duration: 900.ms),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: FilledButton(
            onPressed: busy ? null : onOpen,
            child: busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.welcomePackOpen),
          ),
        ),
      ),
    );
  }
}

/// Révélation simple des cartes reçues (l'animation complète de booster
/// arrive en phase 3).
class _RevealDialog extends ConsumerWidget {
  const _RevealDialog({required this.cards, this.title});
  final List<OwnedCard> cards;

  /// Titre (par défaut : « Tu as reçu N cartes ! »).
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final variants = ref.watch(allVariantsProvider).value ?? const {};
    const order = ['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'];
    final sorted = [...cards]
      ..sort((a, b) => order.indexOf(variants[a.variantId]?.rarete ?? 'commune')
          .compareTo(order.indexOf(variants[b.variantId]?.rarete ?? 'commune')));
    final editionId = sorted.isEmpty ? null : sorted.first.cardId.split(':').first;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title ?? l.welcomePackReceived(cards.length),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: kCardAspect,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, i) {
                final o = sorted[i];
                final view = buildCardView(ref, cardId: o.cardId, owned: o);
                if (view == null) return const SizedBox();
                // KeyedSubtree : TradingCard a déjà un champ « animate », qui masque l'extension.
                return KeyedSubtree(child: TradingCard(view: view, animate: false))
                    .animate(delay: (90 * i).ms)
                    .fadeIn(duration: 300.ms)
                    .scaleXY(begin: 0.6, end: 1, curve: Curves.easeOutBack, duration: 420.ms);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(editionId == null ? '/album' : '/album/$editionId');
                },
                child: Text(l.browseEditions),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
