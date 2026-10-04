import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('StatFormula', () {
    test('normalisation bornée entre 0 et 1', () {
      expect(StatFormula.norm('slpm', 0), 0);
      expect(StatFormula.norm('slpm', 100), 1);
      expect(StatFormula.norm('slpm', 4.25), closeTo(0.5, 1e-9));
    });

    test('toutes les stats restent dans [30, 99]', () {
      const extremes = [
        RealStats(),
        RealStats(
          strikesLandedPerMin: 50,
          strikingAccuracyPct: 100,
          strikesAbsorbedPerMin: 0,
          strikingDefensePct: 100,
          takedownsPer15: 30,
          takedownAccuracyPct: 100,
          takedownDefensePct: 100,
          submissionsPer15: 10,
          knockdownsPer15: 5,
          avgFightTimeSeconds: 1500,
          wins: 30,
          losses: 0,
          winsKo: 30,
          winsSubmission: 0,
          lossesKo: 0,
          ufcFights: 1000,
          fiveRoundDecisionWins: 10,
        ),
        RealStats(
          strikesLandedPerMin: 0,
          strikingAccuracyPct: 0,
          strikesAbsorbedPerMin: 20,
          strikingDefensePct: 0,
          takedownsPer15: 0,
          takedownAccuracyPct: 0,
          takedownDefensePct: 0,
          submissionsPer15: 0,
          knockdownsPer15: 0,
          avgFightTimeSeconds: 10,
          wins: 1,
          losses: 20,
          winsKo: 0,
          winsSubmission: 0,
          lossesKo: 20,
          ufcFights: 1000,
        ),
      ];
      for (final r in extremes) {
        final s = StatFormula.compute(r);
        for (final v in s.values.values) {
          expect(v, inInclusiveRange(30, 99));
        }
      }
    });

    test('sans aucune donnée : valeurs neutres marquées estimées', () {
      final s = StatFormula.compute(const RealStats());
      expect(s.estimated, containsAll(StatKind.values));
      expect(s[StatKind.frappe], 65); // 30 + 69 × 0,5 arrondi
    });

    test('un KO éclair unique ne donne pas une puissance maximale', () {
      const debutant = RealStats(wins: 1, losses: 0, winsKo: 1, knockdownsPer15: 1.2, ufcFights: 1);
      const veteran = RealStats(wins: 20, losses: 2, winsKo: 18, knockdownsPer15: 1.2, ufcFights: 15);
      final a = StatFormula.compute(debutant)[StatKind.puissance];
      final b = StatFormula.compute(veteran)[StatKind.puissance];
      expect(a, lessThan(b));
      expect(a, lessThan(90));
      expect(b, greaterThan(85));
    });

    test('le menton baisse avec les défaites par KO, sans effet de fiabilité', () {
      const solide = RealStats(wins: 20, losses: 2, lossesKo: 0, ufcFights: 1);
      const fragile = RealStats(wins: 20, losses: 8, lossesKo: 6, ufcFights: 1);
      expect(StatFormula.compute(solide)[StatKind.menton], 99);
      expect(StatFormula.compute(fragile)[StatKind.menton], lessThan(45));
    });

    test('profil de frappeur vs lutteur', () {
      const frappeur = RealStats(
        strikesLandedPerMin: 6.5, strikingAccuracyPct: 58, knockdownsPer15: 1.0,
        wins: 15, losses: 2, winsKo: 12, winsSubmission: 0,
        takedownsPer15: 0.1, takedownAccuracyPct: 20, takedownDefensePct: 70,
        submissionsPer15: 0, ufcFights: 12,
      );
      const lutteur = RealStats(
        strikesLandedPerMin: 2.5, strikingAccuracyPct: 45, knockdownsPer15: 0.1,
        wins: 15, losses: 2, winsKo: 2, winsSubmission: 3,
        takedownsPer15: 5.5, takedownAccuracyPct: 55, takedownDefensePct: 92,
        submissionsPer15: 0.5, ufcFights: 12,
      );
      expect(StatFormula.compute(frappeur).style, FighterStyle.frappeur);
      expect(StatFormula.compute(lutteur).style, FighterStyle.lutteur);
    });

    test('bonus de rareté plafonné à 99', () {
      final s = GameStats({for (final k in StatKind.values) k: 97});
      expect(s.withBonus(6)[StatKind.cardio], 99);
    });

    test('lecture du JSON de data/fighters', () {
      final r = RealStats.fromFighterJson({
        'stats_ufc': {'frappes_par_min': 5.01, 'precision_frappe_pct': 61, 'duree_moyenne_combat_s': 642},
        'palmares': {'victoires': 13, 'defaites': 4, 'victoires_ko': 11, 'defaites_ko': 2},
        'ufc': {'combats_ufc': 13, 'victoires_decision_5_rounds': 0},
      });
      expect(r.strikesLandedPerMin, 5.01);
      expect(r.totalFights, 17);
      final s = StatFormula.compute(r);
      expect(GameStats.fromJson(s.toJson()).values, s.values);
    });
  });

  test('WeightClass.distanceTo', () {
    expect(WeightClass.legers.distanceTo(WeightClass.moyens), 2);
    expect(WeightClass.fromKey('mi_lourds'), WeightClass.miLourds);
    expect(WeightClass.fromKey('inconnu'), isNull);
  });
}
