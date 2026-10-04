import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:octogone/core/l10n.dart';
import 'package:octogone/core/theme.dart';
import 'package:octogone/data/repositories/content_providers.dart';
import 'package:octogone/domain/models.dart';
import 'package:octogone/features/album/binder_screen.dart';
import 'package:octogone/features/auth/login_screen.dart';
import 'package:octogone/features/cards/card_back.dart';
import 'package:octogone/features/cards/card_view.dart';
import 'package:octogone/features/cards/holo_layer.dart';
import 'package:octogone/features/cards/interactive_card.dart';
import 'package:octogone/features/cards/trading_card.dart';
import 'package:octogone/features/fighters/fighter_detail_screen.dart';
import 'package:octogone/features/fighters/fighters_screen.dart';

Fighter _fighter(String id, String nom,
        {String categorie = 'mi_lourds', bool champion = false, List<String> aVerifier = const []}) =>
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
      'ufc': {
        'combats_ufc': 13,
        'victoires_ufc': 10,
        'defaites_ufc': 3,
        'technique_favorite': {'technique': 'rear-naked choke', 'finitions': 3},
      },
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

final _edition = Edition({
  'id': 'ed',
  'nom': '2024 Topps Chrome UFC',
  'annee': 2024,
  'type': 'reelle',
  'famille_cadre': 'chrome',
  'sources': <String>[],
});
final _series = CardSeries({'id': 'ed:BASE', 'edition_id': 'ed', 'code': 'BASE', 'nom': 'Base', 'type': 'base', 'nb_cartes': 200});
final _cards = [
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
  CardDef({
    'id': 'ed:2',
    'edition_id': 'ed',
    'series_id': 'ed:BASE',
    'numero': '2',
    'ordre': 1,
    'fighter_ids': ['zhang-weili'],
    'nom_imprime': 'Zhang Weili',
  }),
];
final _variants = {
  'ed:BASE:base': Variant({'id': 'ed:BASE:base', 'series_id': 'ed:BASE', 'edition_id': 'ed', 'nom': 'Base', 'rarete': 'commune', 'effet': 'base', 'reel': true}),
  'ed:BASE:gold-refractor': Variant({'id': 'ed:BASE:gold-refractor', 'series_id': 'ed:BASE', 'edition_id': 'ed', 'nom': 'Gold Refractor', 'rarete': 'epique', 'effet': 'refractor', 'couleur': '#E8B04A', 'tirage': 50, 'reel': true, 'bonus_stats': 3, 'ordre': 1}),
  'ed:BASE:superfractor': Variant({'id': 'ed:BASE:superfractor', 'series_id': 'ed:BASE', 'edition_id': 'ed', 'nom': 'SuperFractor', 'rarete': 'mythique', 'effet': 'superfractor', 'tirage': 1, 'reel': true, 'bonus_stats': 6, 'ordre': 2}),
};
final _owned = [
  OwnedCard({'id': 'o1', 'card_id': 'ed:1', 'variant_id': 'ed:BASE:gold-refractor', 'numero_serie': 12, 'tirage': 50, 'origine': 'booster'}),
];

List<Override> _overrides({List<OwnedCard>? owned}) => [
      fightersProvider.overrideWith((ref) => Stream.value(_fighters)),
      imagesProvider.overrideWith((ref) => Stream.value(const <String, ImageRef>{})),
      editionsProvider.overrideWith((ref) => Stream.value([_edition])),
      seriesForEditionProvider.overrideWith((ref, id) => Stream.value([_series])),
      cardsForEditionProvider.overrideWith((ref, id) => Stream.value(_cards)),
      cardsForFighterProvider.overrideWith((ref, id) => Stream.value(const <CardDef>[])),
      variantsForEditionProvider.overrideWith((ref, id) => Stream.value(_variants.values.toList())),
      allCardsProvider.overrideWith((ref) => Stream.value({for (final c in _cards) c.id: c})),
      allSeriesProvider.overrideWith((ref) => Stream.value({_series.id: _series})),
      allVariantsProvider.overrideWith((ref) => Stream.value(_variants)),
      rivalriesProvider.overrideWith((ref) => Stream.value(const <Rivalry>[])),
      eventsProvider.overrideWith((ref) => Stream.value(const <String, EventInfo>{})),
      ownedCardsProvider.overrideWith((ref) => Stream.value(owned ?? _owned)),
      holoProgramProvider.overrideWith((ref) async => null),
    ];

Widget _wrap(Widget child, {List<Override>? overrides, Locale? locale}) => ProviderScope(
      overrides: overrides ?? _overrides(),
      child: MaterialApp(
        theme: buildTheme(),
        locale: locale,
        supportedLocales: appLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
        home: child,
      ),
    );

/// Construit une CardView sans Riverpod (pour tester les widgets de carte).
CardView _view({String variant = 'ed:BASE:gold-refractor', OwnedCard? owned}) => CardView(
      card: _cards.first,
      variant: _variants[variant]!,
      fighters: [_fighters.first],
      edition: _edition,
      series: _series,
      owned: owned,
      seriesTotal: 200,
    );

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Connexion : validation (français)', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen(), locale: const Locale('fr')));
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Email invalide'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
  });

  testWidgets('Langue du téléphone : anglais', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Fighter cards among friends'), findsOneWidget);
  });

  testWidgets('Langue non prise en charge : repli sur le français', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('Combattants : liste, recherche et filtre champions', (tester) async {
    await tester.pumpWidget(_wrap(const FightersScreen(), locale: const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsOneWidget);
    expect(find.text('Zhang Weili'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('fighters-search')), 'zhang');
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsNothing);
    await tester.enterText(find.byKey(const Key('fighters-search')), '');
    await tester.tap(find.text('Champions'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Pereira'), findsOneWidget);
    expect(find.text('Zhang Weili'), findsNothing);
  });

  testWidgets('Fiche combattant : stats, distinctions dans la langue, pas de sources', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_wrap(const FighterDetailScreen(fighterId: 'alex-pereira'), locale: const Locale('fr')));
    await tester.pumpAndSettle();
    for (final label in ['Frappe', 'Puissance', 'Lutte', 'Soumission', 'Défense', 'Cardio', 'Menton']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Champion UFC des poids mi-lourds (2 fois)'), findsOneWidget);
    expect(find.textContaining('À vérifier : allonge_cm'), findsOneWidget);
    expect(find.text('Sources'), findsNothing);
    expect(find.textContaining('Wikipedia'), findsNothing);

    await tester.pumpWidget(_wrap(const FighterDetailScreen(fighterId: 'alex-pereira'), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('UFC Light Heavyweight Champion (2×)'), findsOneWidget);
    expect(find.text('Striking'), findsOneWidget);
  });

  testWidgets('Recto : nom, numéro dans la série, numéro de série, note avec bonus', (tester) async {
    await tester.pumpWidget(_wrap(Center(child: SizedBox(width: 300, child: TradingCard(view: _view(owned: _owned.first))))));
    await tester.pump();
    expect(find.text('ALEX PEREIRA'), findsOneWidget);
    expect(find.text('1/200'), findsOneWidget);
    expect(find.text('12/50'), findsOneWidget);
    expect(find.text('RC'), findsOneWidget);
    expect(find.text('GOLD REFRACTOR'), findsOneWidget);
    final withBonus = _fighters.first.stats.withBonus(3).overall;
    expect(find.text('$withBonus'), findsOneWidget);
  });

  testWidgets('Verso : stats avec bonus et coup signature débloqué (épique)', (tester) async {
    await tester.pumpWidget(_wrap(Center(child: SizedBox(width: 300, child: CardBack(view: _view()))), locale: const Locale('fr')));
    await tester.pump();
    expect(find.text('FRA'), findsOneWidget);
    expect(find.text('Étranglement arrière'), findsOneWidget);
    expect(find.text('Débloqué à partir d’Épique'), findsNothing);
    expect(find.text('Bonus de rareté +3'), findsOneWidget);
    expect(find.textContaining('Sources'), findsNothing);
  });

  testWidgets('Verso : coup signature verrouillé sur une commune', (tester) async {
    await tester.pumpWidget(
        _wrap(Center(child: SizedBox(width: 300, child: CardBack(view: _view(variant: 'ed:BASE:base')))), locale: const Locale('fr')));
    await tester.pump();
    expect(find.text('Débloqué à partir d’Épique'), findsOneWidget);
  });

  testWidgets('Carte interactive : se retourne au toucher', (tester) async {
    await tester.pumpWidget(_wrap(
      Center(child: SizedBox(width: 300, child: InteractiveCard(view: _view(), useSensors: false))),
      locale: const Locale('fr'),
    ));
    await tester.pump();
    expect(find.byType(TradingCard), findsOneWidget);
    expect(find.byType(CardBack), findsNothing);
    await tester.tap(find.byType(InteractiveCard));
    await tester.pumpAndSettle();
    expect(find.byType(CardBack), findsOneWidget);
    await tester.tap(find.byType(InteractiveCard));
    await tester.pumpAndSettle();
    expect(find.byType(TradingCard), findsOneWidget);
  });

  testWidgets('Classeur : emplacements vides, complétion, filtre possédées, checklist', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_wrap(const BinderScreen(editionId: 'ed'), locale: const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('1/2 · 50 %'), findsOneWidget);
    expect(find.text('Page 1/1'), findsOneWidget);
    // Carte 1 possédée (Gold Refractor 12/50), carte 2 : emplacement vide
    expect(find.text('12/50'), findsOneWidget);
    expect(find.text('Zhang Weili'), findsOneWidget);

    await tester.tap(find.text('Possédées'));
    await tester.pumpAndSettle();
    expect(find.text('Zhang Weili'), findsNothing);

    await tester.tap(find.byTooltip('Checklist'));
    await tester.pumpAndSettle();
    expect(find.text('Gold Refractor /50'), findsOneWidget);
    expect(find.text('SuperFractor 1/1'), findsOneWidget);
  });
}
