import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/techniques.dart';
import '../../core/theme.dart';
import '../../widgets/fighter_widgets.dart';
import 'card_view.dart';
import 'effects.dart';
import 'trading_card.dart' show kCardAspect, kCardHeight, kCardWidth;

const _display = 'Oswald';

/// Verso d'une carte : stats de jeu (bonus de rareté inclus), palmarès, faits
/// marquants, coup signature. Pas de mention de source (voir l'écran Crédits).
class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final spec = effectFor(
      view.effect,
      couleur: view.variant.couleur,
      frameFamily: view.frameFamily,
    );
    final frame = spec.frame ?? frameColors(view.frameFamily);
    return AspectRatio(
      aspectRatio: kCardAspect,
      child: FittedBox(
        child: Container(
          width: kCardWidth,
          height: kCardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: frame,
            ),
          ),
          padding: const EdgeInsets.all(9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              color: const Color(0xFF111319),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                child: view.isDuel
                    ? _DuelBack(view: view)
                    : view.event != null
                    ? _EventBack(view: view)
                    : _FighterBack(view: view),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: _display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            fontFamily: _display,
            fontSize: 13,
            color: AppColors.gold,
          ),
        ),
    ],
  );
}

class _FighterBack extends StatelessWidget {
  const _FighterBack({required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = view.fighter;
    if (f == null) return Center(child: Text(view.card?.nomImprime ?? ''));
    final bonus = view.variant.bonusStats;
    final base = f.stats;
    final boosted = base.withBonus(bonus);
    final p = f.palmares;
    final highlights = f.distinctions(context.lang).take(3).toList();
    final technique = techniqueLabel(
      (f.ufc['technique_favorite'] as Map?)?['technique'] as String?,
      context.lang,
    );
    final unlocked = view.rarity.unlocksSignature;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: f.nom,
          subtitle:
              '${flagEmoji(f.pays)} ${countryLabel(context, f.pays)} · ${weightClassLabel(l, f.categorie)}',
          trailing: view.numberLabel,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final k in StatKind.values)
                    _StatLine(
                      label: statShort(l, k),
                      value: boosted[k],
                      bonus: boosted[k] - base[k],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Text(
                      '${boosted.overall}',
                      style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    styleLabel(l, base.style),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (bonus > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.cardStatBonus(bonus),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SectionTitle(l.cardRecord),
        Text(
          '${f.record}   (KO ${p['victoires_ko'] ?? '—'} · SUB ${p['victoires_soumission'] ?? '—'} · DEC ${p['victoires_decision'] ?? '—'})',
          style: const TextStyle(fontSize: 12),
        ),
        // Zone extensible et rognée : le verso ne déborde jamais, même avec de longues distinctions.
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (highlights.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _SectionTitle(l.cardHighlights),
                  for (final h in highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        '• $h',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (technique != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: unlocked
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : Colors.white10,
              border: Border.all(
                color: unlocked ? AppColors.gold : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  unlocked ? Icons.bolt : Icons.lock_outline,
                  size: 16,
                  color: unlocked ? AppColors.gold : Colors.white54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cardSignatureMove.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        technique,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: unlocked ? Colors.white : Colors.white54,
                        ),
                      ),
                      if (!unlocked)
                        Text(
                          l.cardSignatureLocked,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        _BackFooter(view: view),
      ],
    );
  }
}

class _DuelBack extends StatelessWidget {
  const _DuelBack({required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final a = view.fighters[0], b = view.fighters[1];
    final r = view.rivalry;
    final names = {a.id: a.nom, b.id: b.nom};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: '${a.nom.split(' ').last} vs ${b.nom.split(' ').last}',
          trailing: view.numberLabel,
        ),
        const SizedBox(height: 8),
        if (r != null)
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a.nom} ${r.scoreFor(a.id)} ${b.nom}',
                    style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 16,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final c in r.combats.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 74,
                            child: Text(
                              '${c['date']}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c['evenement']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                                Text(
                                  '${names[c['vainqueur']] ?? '—'} · ${c['methode']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          const Spacer(),
        _BackFooter(view: view),
      ],
    );
  }
}

class _EventBack extends StatelessWidget {
  const _EventBack({required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final ev = view.event!;
    final d = ev.date == null ? null : DateTime.tryParse(ev.date!);
    final date = d == null
        ? null
        : DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(d);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: ev.nom,
          subtitle: [?date, ?ev.lieu, ?ev.ville].join(' · '),
          trailing: view.numberLabel,
        ),
        const SizedBox(height: 10),
        if (ev.resultat(context.lang) != null)
          Text(
            ev.resultat(context.lang)!,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 8),
        if (ev.contexte(context.lang) != null)
          Text(
            ev.contexte(context.lang)!,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        const Spacer(),
        _BackFooter(view: view),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    required this.bonus,
  });
  final String label;
  final int value;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    final color = value >= 85
        ? AppColors.gold
        : value >= 70
        ? AppColors.success
        : value >= 55
        ? AppColors.steel
        : AppColors.crimson;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: _display,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value / 99,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (bonus > 0)
                    TextSpan(
                      text: ' +$bonus',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 9.5,
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: _display,
        fontSize: 10,
        letterSpacing: 1.4,
        color: AppColors.gold,
      ),
    ),
  );
}

class _BackFooter extends StatelessWidget {
  const _BackFooter({required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parts = <String>[
      ?view.edition?.nom,
      if (view.series != null && view.series!.type != 'base') view.series!.nom,
      if (view.effect != 'base') variantLabel(l, view.effect, view.variant.nom),
      rarityLabel(l, view.variant.rarete),
      if (view.printRun != null) l.cardPrintRun(view.printRun!),
    ];
    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 9.5,
        color: Colors.white54,
        letterSpacing: 0.3,
      ),
    );
  }
}
