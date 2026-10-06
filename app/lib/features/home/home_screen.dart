import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/pressable.dart';
import '../../widgets/tilt_builder.dart';
import '../auth/auth_providers.dart';
import '../boosters/booster_flow.dart';
import '../boosters/booster_pack.dart';
import '../boosters/booster_service.dart';
import '../defis/defis_service.dart';
import 'welcome_pack.dart';

/// Accueil : le booster de la collection du moment occupe l'essentiel de
/// l'écran (à la manière de TCG Pocket), avec l'état des boosters gratuits et
/// l'accès aux autres collections en bas à droite.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.useSensors = true});

  final bool useSensors;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pager = PageController(viewportFraction: 0.78);
  int _page = 0;
  String? _edition;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _open(BoosterType b) async {
    final payment = await choosePayment(context, ref, b);
    if (payment == null || !mounted) return;
    await context.push('/booster/${Uri.encodeComponent(b.id)}?paiement=$payment');
    if (!mounted) return;
    ref
      ..invalidate(boosterStatusProvider)
      ..invalidate(walletProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final boosters = ref.watch(currentBoostersProvider);
    final types = ref.watch(boosterTypesProvider);

    // Revenir sur le premier booster quand on change de collection
    final edition = boosters.firstOrNull?.editionId;
    if (edition != _edition) {
      _edition = edition;
      _page = 0;
      if (_pager.hasClients) _pager.jumpToPage(0);
    }
    final current = boosters.isEmpty ? null : boosters[_page.clamp(0, boosters.length - 1)];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          _HomeTopBar(pseudo: profile?.pseudo),
          if (profile != null && !profile.welcomePackReceived)
            const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 4), child: WelcomePackCard())
          else if (profile != null && !profile.tacticStarterReceived)
            const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 4), child: TacticStarterCard()),
          Expanded(
            child: boosters.isEmpty
                ? _EmptyBoosters(loading: types.isLoading)
                : Column(children: [
                    const SizedBox(height: 2),
                    if (boosters.first.enVedette)
                      Text(
                        l.homeFeatured.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold.withValues(alpha: 0.85),
                        ),
                      ).animate().fadeIn(duration: Motion.slow),
                    Text(
                      boosters.first.nom.toUpperCase(),
                      key: const Key('home-collection-title'),
                      style: const TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 30,
                        height: 1.1,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black, blurRadius: 16)],
                      ),
                    ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.25, end: 0, curve: Motion.curve),
                    Expanded(
                      child: TiltBuilder(
                        useSensors: widget.useSensors,
                        builder: (context, tilt) => PageView.builder(
                          key: const Key('home-boosters'),
                          controller: _pager,
                          itemCount: boosters.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (context, i) => _PackSlide(
                            booster: boosters[i],
                            tilt: tilt,
                            focused: i == _page,
                            onTap: () => i == _page
                                ? _open(boosters[i])
                                : _pager.animateToPage(i, duration: 300.ms, curve: Curves.easeOut),
                          ),
                        ),
                      ).animate().fadeIn(delay: 120.ms, duration: Motion.slow).scaleXY(begin: 0.92, end: 1, curve: Motion.curve),
                    ),
                    if (boosters.length > 1) _Dots(count: boosters.length, index: _page),
                    const SizedBox(height: 4),
                    if (current != null) _PackCaption(booster: current),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _FreeStatus()),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(children: [
              Expanded(
                child: current == null
                    ? const SizedBox()
                    : FilledButton.icon(
                        key: const Key('home-open'),
                        onPressed: () => _open(current),
                        icon: const Icon(Icons.bolt),
                        label: Text(l.boosterOpen, overflow: TextOverflow.ellipsis),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 168),
                child: OutlinedButton.icon(
                  key: const Key('home-collections'),
                  onPressed: () => showCollectionsSheet(context, ref),
                  icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                  label: Text(l.boosterChooseCollections, maxLines: 2, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ]).animate().fadeIn(delay: 240.ms, duration: Motion.slow).slideY(begin: 0.4, end: 0, curve: Motion.curve),
          ),
        ]),
      ),
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar({required this.pseudo});
  final String? pseudo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final coins = ref.watch(walletProvider).value?.pieces;
    final sync = ref.watch(syncControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      child: Row(children: [
        Expanded(
          child: Text(
            pseudo == null ? l.appTitle : l.helloUser(pseudo!),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        _Chip(
          key: const Key('home-defis'),
          icon: Icons.flag_outlined,
          text: l.defisTitle,
          tooltip: l.defisTitle,
          color: AppColors.gold,
          badge: ref.watch(defisClaimableProvider),
          onTap: () => context.push('/defis'),
        ),
        const SizedBox(width: 6),
        _Chip(
          key: const Key('home-coins'),
          icon: Icons.toll,
          text: coins == null ? '–' : '$coins',
          tooltip: l.coins(coins ?? 0),
          color: AppColors.gold,
          onTap: () => context.push('/boutique'),
        ),
        IconButton(
          tooltip: l.sync,
          onPressed: sync.running
              ? null
              : () {
                  ref
                    ..invalidate(walletProvider)
                    ..invalidate(defisProvider)
                    ..invalidate(boosterStatusProvider);
                  ref.read(syncControllerProvider.notifier).sync();
                },
          icon: sync.running
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(sync.error != null ? Icons.cloud_off : Icons.sync,
                  color: sync.error != null ? AppColors.warning : null),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.icon, required this.text, required this.tooltip, this.color, this.onTap, this.badge = 0});
  final IconData icon;
  final String text;
  final String tooltip;
  final Color? color;
  final VoidCallback? onTap;

  /// Pastille (nombre de récompenses à récupérer).
  final int badge;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Stack(clipBehavior: Clip.none, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 16, color: color ?? AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
              if (badge > 0)
                Positioned(
                  top: -5,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(10)),
                    child: Text('$badge', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ),
        ),
      );
}

/// Un booster du carrousel : flotte doucement, s'incline avec le téléphone.
class _PackSlide extends StatelessWidget {
  const _PackSlide({required this.booster, required this.tilt, required this.focused, required this.onTap});
  final BoosterType booster;
  final Offset tilt;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pack = BoosterPack(booster: booster, tilt: focused ? tilt : Offset.zero, animate: focused);
    return LayoutBuilder(builder: (context, c) {
      final h = math.min(c.maxHeight * 0.92, c.maxWidth / kPackAspect);
      Widget child = SizedBox(height: h, width: h * kPackAspect, child: pack);
      if (focused) {
        child = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(tilt.dx * 0.18)
            ..rotateX(-tilt.dy * 0.12),
          child: child,
        );
        if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
          child = child
              .animate(onPlay: (ctl) => ctl.repeat(reverse: true))
              .moveY(begin: -5, end: 5, duration: 2200.ms, curve: Curves.easeInOut);
        }
      }
      final accent = _accent(booster);
      return Center(
        child: AnimatedScale(
          scale: focused ? 1 : 0.86,
          duration: Motion.medium,
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: focused ? 1 : 0.55,
            duration: Motion.medium,
            child: Pressable(
              key: Key('home-pack-${booster.id}'),
              onTap: onTap,
              child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                // Socle lumineux sous le sachet (ombre portée teintée)
                if (focused)
                  Positioned(
                    bottom: -h * 0.04,
                    child: IgnorePointer(
                      child: Container(
                        width: h * kPackAspect * 1.1,
                        height: h * 0.09,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(h, h * 0.09)),
                          gradient: RadialGradient(colors: [
                            accent.withValues(alpha: 0.45),
                            accent.withValues(alpha: 0.12),
                            Colors.transparent,
                          ], stops: const [0, 0.5, 1]),
                        ),
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(boxShadow: [
                    if (focused) BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 44, spreadRadius: -8),
                  ]),
                  child: child,
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

Color _accent(BoosterType b) {
  final s = b.visuel['accent'] as String?;
  if (s == null || s.length != 7) return AppColors.gold;
  return Color(int.parse('FF${s.substring(1)}', radix: 16));
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? AppColors.gold : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      );
}

/// « Premium · 10 cartes · Probabilités »
class _PackCaption extends ConsumerWidget {
  const _PackCaption({required this.booster});
  final BoosterType booster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(boosterStatusProvider).value;
    final free = status != null && (status.testMode || (!booster.isPremium && status.charges > 0));
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          '${booster.isPremium ? l.boosterPremium : l.boosterStandard} · ${l.boosterCards(booster.nbCartes)}'
          '${free ? '' : ' · ${l.boosterPrice(booster.prixPieces)}'}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        TextButton(
          key: const Key('home-odds'),
          onPressed: () => showOddsSheet(context, ref, booster),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: Text(l.boosterOdds),
        ),
      ],
    );
  }
}

/// État des boosters gratuits : mode test, recharges prêtes, compte à rebours.
class _FreeStatus extends ConsumerStatefulWidget {
  const _FreeStatus();

  @override
  ConsumerState<_FreeStatus> createState() => _FreeStatusState();
}

class _FreeStatusState extends ConsumerState<_FreeStatus> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final s = ref.read(boosterStatusProvider).value;
      final left = s?.remaining(DateTime.now());
      if (left != null && left == Duration.zero) {
        ref.invalidate(boosterStatusProvider);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = ref.watch(boosterStatusProvider);
    final s = status.value;
    if (s == null) return const SizedBox();
    final left = s.remaining(DateTime.now());
    final (icon, color, lines) = s.testMode
        ? (Icons.all_inclusive, AppColors.gold, [l.boosterTestMode])
        : (
            Icons.card_giftcard,
            s.charges > 0 ? AppColors.success : AppColors.textMuted,
            [
              if (s.charges > 0) l.boosterFreeReady(s.charges),
              if (left != null && s.charges < s.capacity) l.boosterNextFree(formatDuration(l, left)),
            ],
          );
    if (lines.isEmpty) return const SizedBox();
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          lines.join(' · '),
          key: const Key('home-free-status'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: color, height: 1.25),
        ),
      ),
    ]);
  }
}

class _EmptyBoosters extends StatelessWidget {
  const _EmptyBoosters({required this.loading});
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_sync, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(l.syncWaiting, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}
