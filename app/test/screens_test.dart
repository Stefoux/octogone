import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:octogone/core/l10n.dart';
import 'package:octogone/core/sounds.dart';
import 'package:octogone/core/theme.dart';
import 'package:octogone/data/repositories/content_providers.dart';
import 'package:octogone/domain/models.dart';
import 'package:octogone/features/album/binder_screen.dart';
import 'package:octogone/features/auth/auth_providers.dart';
import 'package:octogone/features/auth/login_screen.dart';
import 'package:octogone/features/boosters/booster_service.dart';
import 'package:octogone/features/boosters/opening_screen.dart';
import 'package:octogone/features/cards/card_back.dart';
import 'package:octogone/features/cards/card_backside.dart';
import 'package:octogone/features/cards/card_view.dart';
import 'package:octogone/features/cards/holo_layer.dart';
import 'package:octogone/features/cards/interactive_card.dart';
import 'package:octogone/features/cards/trading_card.dart';
import 'package:octogone/features/fighters/fighter_detail_screen.dart';
import 'package:octogone/features/entry/entry_screen.dart';
import 'package:octogone/features/fighters/fighters_screen.dart';
import 'package:octogone/widgets/rarity_backdrop.dart';
import 'package:octogone/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// --- Boosters ---------------------------------------------------------------

const _slotsStandard = {
  'slots': [
    {'nb': 4, 'poids': {'commune': 100}},
    {'nb': 1, 'poids': {'peu_commune': 75, 'rare': 22, 'epique': 3}},
    {'nb': 1, 'poids': {'peu_commune': 50, 'rare': 33, 'epique': 12.5, 'legendaire': 4, 'mythique': 0.5}},
  ],
};

BoosterType _booster(String edition, String nom, String type, {bool vedette = false}) => BoosterType({
      'id': '$edition:$type',
      'edition_id': edition,
      'nom': nom,
      'type': type,
      'nb_cartes': type == 'premium' ? 10 : 6,
      'prix_pieces': type == 'premium' ? 250 : 100,
      'en_vedette': vedette,
      'visuel': {'couleurs': ['#0E0F14', '#2A2416', '#E8B04A'], 'accent': '#E8B04A', 'motif': 'octogone'},
      'composition': _slotsStandard,
    });

final _boosters = [
  _booster('saison-2026', 'Saison 2026', 'standard', vedette: true),
  _booster('saison-2026', 'Saison 2026', 'premium'),
  _booster('ed', '2024 Topps Chrome UFC', 'standard'),
];

class _FakeBoosters implements BoosterService {
  _FakeBoosters({this.testMode = false});
  final bool testMode;
  final opened = <(String, String)>[];

  @override
  Future<BoosterStatus> status() async => BoosterStatus(
        testMode: testMode,
        charges: 1,
        capacity: 2,
        nextIn: const Duration(hours: 3, minutes: 20),
        pityThreshold: 40,
        sinceLegendary: 12,
        fetchedAt: DateTime.now(),
      );

  @override
  Future<List<PulledCard>> open(String typeId, {String payment = 'gratuit'}) async {
    opened.add((typeId, payment));
    return [
      PulledCard({'owned_id': 'n1', 'card_id': 'ed:2', 'variant_id': 'ed:BASE:base', 'rarete': 'commune', 'nouvelle': true}),
      PulledCard({'owned_id': 'n2', 'card_id': 'ed:1', 'variant_id': 'ed:BASE:base', 'rarete': 'commune', 'nouvelle': false}),
      PulledCard({
        'owned_id': 'n3',
        'card_id': 'ed:1',
        'variant_id': 'ed:BASE:gold-refractor',
        'rarete': 'epique',
        'numero_serie': 7,
        'tirage': 50,
        'nouvelle': true,
      }),
    ];
  }
}

class _IdleSync extends SyncController {
  @override
  SyncStatus build() => SyncStatus(lastSync: DateTime(2026, 10, 4));
  @override
  Future<void> sync() async {}
}

List<Override> _boosterOverrides(_FakeBoosters fake) => [
      ..._overrides(),
      boosterServiceProvider.overrideWithValue(fake),
      boosterTypesProvider.overrideWith((ref) => Stream.value(_boosters)),
      walletProvider.overrideWith((ref) async => 480),
      profileProvider.overrideWith((ref) async => const Profile(
            id: 'u1',
            pseudo: 'Testeur',
            friendCode: 'ABCD',
            isAdmin: false,
            adminMode: false,
            welcomePackReceived: true,
          )),
      syncControllerProvider.overrideWith(_IdleSync.new),
      soundFxProvider.overrideWithValue(SoundFx(enabled: false)),
    ];

/// Avance de plusieurs images (les animations en boucle empêchent pumpAndSettle).
Future<void> _frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

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

  testWidgets('Accueil : booster en vedette au centre, statut gratuit, autres collections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneScreen(tester);
    final fake = _FakeBoosters();
    await tester.pumpWidget(_wrap(const HomeScreen(useSensors: false), overrides: _boosterOverrides(fake), locale: const Locale('fr')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    String title() => tester.widget<Text>(find.byKey(const Key('home-collection-title'))).data!;
    expect(title(), 'SAISON 2026');
    expect(find.byKey(const Key('home-pack-saison-2026:standard')), findsOneWidget);
    expect(find.textContaining('Standard · 6 cartes'), findsOneWidget);
    expect(find.text('1 booster gratuit prêt · Prochain booster gratuit dans 3 h 20 min'), findsOneWidget);
    expect(find.text('480'), findsOneWidget);
    expect(find.text('Choisir d’autres collections'), findsOneWidget);

    // Bouton en bas à droite : liste des collections, puis bascule sur Topps Chrome
    await tester.tap(find.byKey(const Key('home-collections')));
    await _frames(tester);
    expect(find.text('Collections'), findsOneWidget);
    await tester.ensureVisible(find.text('2024 Topps Chrome UFC'));
    await tester.pump();
    await tester.tap(find.text('2024 Topps Chrome UFC'));
    await _frames(tester);
    expect(title(), '2024 TOPPS CHROME UFC');
    expect(find.byKey(const Key('home-pack-ed:standard')), findsOneWidget);
  });

  testWidgets('Accueil : probabilités calculées depuis la composition', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneScreen(tester);
    await tester.pumpWidget(
        _wrap(const HomeScreen(useSensors: false), overrides: _boosterOverrides(_FakeBoosters()), locale: const Locale('fr')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('home-odds')));
    await _frames(tester);
    expect(find.text('4 par booster'), findsOneWidget); // communes
    expect(find.text('1 sur 200 boosters'), findsOneWidget); // mythique : 0,5 %
    expect(find.text('Garantie dans 28 boosters au plus tard.'), findsOneWidget);
  });

  testWidgets('Ouverture : glisser pour déchirer, carte par carte, tout révéler, résumé', (tester) async {
    _phoneScreen(tester);
    final fake = _FakeBoosters(testMode: true);
    await tester.pumpWidget(_wrap(
      const BoosterOpeningScreen(typeId: 'saison-2026:standard', useSensors: false),
      overrides: _boosterOverrides(fake),
      locale: const Locale('fr'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Glisse le doigt le long du haut pour déchirer'), findsOneWidget);

    // Un petit glissement ne suffit pas
    await tester.drag(find.byKey(const Key('booster-tear')), const Offset(60, 0));
    await tester.pump();
    expect(fake.opened, isEmpty);

    await tester.drag(find.byKey(const Key('booster-tear')), const Offset(320, 0));
    await tester.pump();
    expect(fake.opened, [('saison-2026:standard', 'gratuit')]);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Touche pour révéler'), findsOneWidget);

    // Première carte : commune, nouvelle
    await tester.tap(find.byKey(const Key('booster-reveal')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('COMMUNE'), findsOneWidget);
    expect(find.text('NOUVELLE'), findsOneWidget);
    expect(find.text('ZHANG WEILI'), findsOneWidget);

    // Suivante
    await tester.tap(find.byKey(const Key('booster-reveal')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('booster-reveal-all')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('NOUVELLE'), findsNWidgets(2));
    expect(find.text('Épique'), findsOneWidget);
    expect(find.text('Ouvrir un autre'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);

    // Ouvrir un autre : retour au sachet (mode test : gratuit, sans confirmation)
    await tester.tap(find.text('Ouvrir un autre'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Glisse le doigt le long du haut pour déchirer'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Écran d’entrée : titre lettre par lettre, cartes phares, tout l’écran pour entrer', (tester) async {
    _phoneScreen(tester);
    var entered = 0;
    await tester.pumpWidget(_wrap(EntryScreen(useSensors: false, onEnter: () => entered++),
        overrides: _boosterOverrides(_FakeBoosters()), locale: const Locale('fr')));
    await tester.pump(const Duration(milliseconds: 100));
    // Au début seul l'octogone se trace : le texte d'entrée n'est pas encore visible
    final cta = find.text('ENTRER DANS L’OCTOGONE');
    expect(cta, findsOneWidget);
    double ctaOpacity() => tester.widget<Opacity>(find.ancestor(of: cta, matching: find.byType(Opacity)).first).opacity;
    expect(ctaOpacity(), 0);
    await _frames(tester, 32);
    expect(ctaOpacity(), greaterThan(0.5));
    for (final letter in ['O', 'C', 'T', 'G', 'N', 'E']) {
      expect(find.text(letter), findsWidgets);
    }
    // Cartes absentes du cache de test : dos de carte autour de l'octogone
    expect(find.byType(CardBackside), findsNWidgets(kPrestigeCards.length));

    // Un toucher n'importe où (ici en haut à gauche) lance l'entrée
    await tester.tapAt(const Offset(30, 120));
    await _frames(tester, 10);
    expect(entered, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Écran d’entrée : animations réduites, tout est affiché d’emblée', (tester) async {
    _phoneScreen(tester);
    var entered = 0;
    await tester.pumpWidget(_wrap(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 780), disableAnimations: true),
        child: EntryScreen(useSensors: false, onEnter: () => entered++),
      ),
      overrides: _boosterOverrides(_FakeBoosters()),
      locale: const Locale('fr'),
    ));
    await tester.pump();
    final cta = find.text('ENTRER DANS L’OCTOGONE');
    expect(tester.widget<Opacity>(find.ancestor(of: cta, matching: find.byType(Opacity)).first).opacity, greaterThan(0.5));
    await tester.tap(find.byKey(const Key('entry-enter')));
    await tester.pump();
    expect(entered, 1);
  });

  testWidgets('Fonds de rareté : chaque niveau s’affiche (commune à mythique)', (tester) async {
    for (final r in ['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique']) {
      await tester.pumpWidget(MaterialApp(home: RarityBackdrop(rarete: r, child: Text(r))));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(r), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
