import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AxisDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sons de l'app (générés par data/scripts/make_sounds.py : style cinématique
/// et métallique, foule et cloche pour les grandes raretés) et retours haptiques.
class SoundFx {
  SoundFx({this.enabled = true});

  bool enabled;
  final _players = <String, AudioPlayer>{};

  /// [balance] : -1 (gauche) à 1 (droite) ; [rate] : vitesse/hauteur (1 = normal).
  Future<void> play(String name, {double volume = 0.9, double balance = 0, double rate = 1}) async {
    if (!enabled) return;
    try {
      final p = _players.putIfAbsent(name, () => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency));
      await p.stop();
      await p.setPlaybackRate(rate);
      await p.play(AssetSource('sounds/$name.wav'), volume: volume, balance: balance);
    } catch (_) {
      // Pas de son (tests, appareil muet) : on ignore.
    }
  }

  /// Envol d'une carte : le son part du côté du geste (plus aigu vers le
  /// haut, plus grave vers le bas).
  Future<void> swipe(AxisDirection direction) => play(
        'swipe',
        volume: 0.8,
        balance: switch (direction) {
          AxisDirection.left => -0.7,
          AxisDirection.right => 0.7,
          _ => 0,
        },
        rate: switch (direction) {
          AxisDirection.up => 1.15,
          AxisDirection.down => 0.85,
          _ => 1,
        },
      );

  /// Son + vibration de révélation selon la rareté.
  Future<void> reveal(String rarete) async {
    switch (rarete) {
      case 'mythique':
        await HapticFeedback.heavyImpact();
        await HapticFeedback.vibrate();
      case 'legendaire':
        await HapticFeedback.heavyImpact();
      case 'epique':
        await HapticFeedback.mediumImpact();
      case 'rare':
        await HapticFeedback.lightImpact();
      default:
        await HapticFeedback.selectionClick();
    }
    await play('reveal_$rarete');
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
  }
}

class SoundSettings extends Notifier<bool> {
  static const _key = 'sons';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? true;
    } catch (_) {}
  }

  Future<void> set(bool v) async {
    state = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, v);
    } catch (_) {}
  }
}

final soundEnabledProvider = NotifierProvider<SoundSettings, bool>(SoundSettings.new);

final soundFxProvider = Provider<SoundFx>((ref) {
  final fx = SoundFx(enabled: ref.watch(soundEnabledProvider));
  ref.onDispose(fx.dispose);
  return fx;
});
