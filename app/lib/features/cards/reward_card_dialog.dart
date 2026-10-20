import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import 'card_view.dart';
import 'trading_card.dart';

/// Montre une carte gagnée en récompense (défi, succès).
Future<void> showRewardCard(BuildContext context, RewardCard card) =>
    showDialog<void>(context: context, builder: (_) => _RewardDialog(card: card));

class _RewardDialog extends ConsumerWidget {
  const _RewardDialog({required this.card});
  final RewardCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = buildCardView(ref, cardId: card.cardId, variantId: card.variantId, owned: card.owned);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.rewardTacticTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kDisplayFont, fontSize: 22, color: AppColors.gold),
            ),
            const SizedBox(height: 14),
            if (view != null)
              SizedBox(
                width: 200,
                child: KeyedSubtree(child: TradingCard(view: view))
                    .animate()
                    .scaleXY(begin: 0.6, end: 1, curve: Curves.easeOutBack, duration: 450.ms)
                    .fadeIn(),
              ),
            const SizedBox(height: 10),
            Text(l.rewardTacticHint, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      ),
    );
  }
}
