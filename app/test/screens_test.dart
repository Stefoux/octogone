import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogone/core/theme.dart';
import 'package:octogone/data/repositories/content_providers.dart';
import 'package:octogone/domain/models.dart';
import 'package:octogone/features/album/edition_screen.dart';
import 'package:octogone/features/auth/login_screen.dart';
import 'package:octogone/features/fighters/fighter_detail_screen.dart';
import 'package:octogone/features/fighters/fighters_screen.dart';

Fighter _fighter(String id, String nom, {String categorie = 'mi_lourds', bool champion = false, List<String> aVerifier = const []}) =>
    Fighter({
      'id': id,
      'nom': nom,
      'surnom': 'Surnom $nom',
      'pays': 'BR',
      'categorie': categorie,
      'statut': 'actif',
      'champion_actuel': champion,
      'palmares': {'victoires': 13, 'defaites': 4, 'nuls': 0, 'victoires_ko': 11, 'defaites_ko': 2},
      'stats_ufc': {'frappes_par_min': 5.01, 'precision_frappe_pct': 61, 'duree_moyenne_combat_s': 642},
      'ufc': {'combats_ufc': 13, 'victoires_ufc': 10, 'defaites_ufc': 3},
      'sources': {'ufc_com': 'https://www.ufc.com/athlete/test'},
      'distinctions': {
        'fr': ['Champion UFC des poids mi-lourds (2 fois)', 'Bonus UFC : 6× Performance de la soirée'],
        'en': ['UFC Light Heavyweight Champion (2×)', 'UFC bonuses: 6× Performance of the Night'],
      },
      'a_verifier': aVerifier,
    });

final _fighters = [
  _fighter('alex-pereira', 'Alex Pereira', champion: true, aVerifier: ['allonge_cm']),
  _fighter('zhang-weili', 'Zhang Weili', categorie: 'mouche_f'),
];

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) => ProviderScope(
      overrides: [
        fightersProvider.overrideWith((ref) => Stream.value(_fighters)),
        imagesProvider.overrideWith((ref) => Stream.value(const <String, ImageRef>{})),
        editionsProvider.overrideWith((ref) => Stream.value([
              Edition({
                'id': 'ed',
                'nom': '2024 Topps Chrome UFC',
                'annee': 2024,
                'type': 'reelle',
                'famille_cadre': 'chrome',
                'sources': ['https://example.org/checklist'],
              }),
            ])),
        cardsForFighterProvider.overrideWith((ref, id) => Stream.value(const <CardDef>[])),
        ...overrides.cast(),
      ],
      child: MaterialApp(theme: buildTheme(), home: child),
    );

void main() {
  testWidgets('Connexion : champs présents et validation', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.text('Se connecter'), findsOneWidget);
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Email invalide'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
  });

  testWidgets('Combattants : liste, recherche et filtre champions', (tester) async {
    await tester.pumpWidget(_wrap(const FightersScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsOneWidget);
    expect(find.text('Zhang Weili'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('fighters-search')), 'zhang');
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsNothing);
    expect(find.text('Zhang Weili'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('fighters-search')), '');
    await tester.tap(find.text('Champions'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsOneWidget);
    expect(find.text('Zhang Weili'), findsNothing);
  });

  testWidgets('Fiche combattant : stats de jeu, palmarès, données à vérifier', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const FighterDetailScreen(fighterId: 'alex-pereira')));
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsOneWidget);
    expect(find.text('Stats de jeu'), findsOneWidget);
    for (final label in ['Frappe', 'Puissance', 'Lutte', 'Soumission', 'Défense', 'Cardio', 'Menton']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Champion'), findsOneWidget);
    expect(find.textContaining('À vérifier : allonge_cm'), findsOneWidget);
    expect(find.text('Palmarès 13-4'), findsOneWidget);
  });

  Future<void> openDetail(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(_wrap(const FighterDetailScreen(fighterId: 'alex-pereira')));
    await tester.pumpAndSettle();
  }

  testWidgets('Distinctions en français, sans sources affichées', (tester) async {
    await openDetail(tester, const Locale('fr', 'FR'));
    expect(find.text('Distinctions'), findsOneWidget);
    expect(find.text('Champion UFC des poids mi-lourds (2 fois)'), findsOneWidget);
    expect(find.textContaining('Wikipedia'), findsNothing);
    expect(find.text('Sources'), findsNothing);
  });

  testWidgets('Distinctions dans la langue du téléphone (anglais)', (tester) async {
    await openDetail(tester, const Locale('en', 'US'));
    expect(find.text('UFC Light Heavyweight Champion (2×)'), findsOneWidget);
    expect(find.text('Champion UFC des poids mi-lourds (2 fois)'), findsNothing);
  });

  testWidgets('Langue non traduite : repli sur le français', (tester) async {
    await openDetail(tester, const Locale('de', 'DE'));
    expect(find.text('Champion UFC des poids mi-lourds (2 fois)'), findsOneWidget);
  });

  testWidgets('Édition : séries, parallèles et tirages', (tester) async {
    await tester.pumpWidget(_wrap(
      const EditionScreen(editionId: 'ed'),
      overrides: [
        seriesForEditionProvider.overrideWith((ref, id) => Stream.value([
              CardSeries({'id': 'ed:BASE', 'edition_id': 'ed', 'code': 'BASE', 'nom': 'Base', 'type': 'base', 'ordre': 0}),
            ])),
        cardsForEditionProvider.overrideWith((ref, id) => Stream.value([
              CardDef({
                'id': 'ed:1',
                'edition_id': 'ed',
                'series_id': 'ed:BASE',
                'numero': '1',
                'ordre': 0,
                'fighter_ids': ['alex-pereira'],
                'nom_imprime': 'Alex Pereira',
                'mentions': ['RC'],
              }),
            ])),
        variantsForEditionProvider.overrideWith((ref, id) => Stream.value([
              Variant({'id': 'v1', 'series_id': 'ed:BASE', 'edition_id': 'ed', 'nom': 'Gold Refractor', 'rarete': 'epique', 'effet': 'refractor', 'tirage': 50, 'reel': true}),
              Variant({'id': 'v2', 'series_id': 'ed:BASE', 'edition_id': 'ed', 'nom': 'SuperFractor', 'rarete': 'mythique', 'effet': 'superfractor', 'tirage': 1, 'reel': true}),
            ])),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('2024 Topps Chrome UFC'), findsOneWidget);
    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();
    expect(find.text('Gold Refractor /50'), findsOneWidget);
    expect(find.text('SuperFractor 1/1'), findsOneWidget);
    expect(find.text('Alex Pereira'), findsOneWidget);
    expect(find.text('RC'), findsOneWidget);
  });
}
