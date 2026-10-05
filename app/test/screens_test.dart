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
import 'package:octogone/features/vitrine/vitrine_screen.dart';
import 'package:octogone/features/atelier/atelier_service.dart';
import 'package:octogone/features/atelier/atelier_widgets.dart';
import 'package:octogone/features/defis/defis_screen.dart';
import 'package:octogone/features/defis/defis_service.dart';
import 'package:octogone/features/vitrine/vitrine_service.dart';
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
  _FakeBoosters({this.testMode = false, this.count = 3});
  final bool testMode;

  /// Nombre de cartes du booster (3 ou plus : des communes s'ajoutent devant).
  final int count;
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
      for (var i = 3; i < count; i++)
        PulledCard({'owned_id': 'x$i', 'card_id': 'ed:2', 'variant_id': 'ed:BASE:base', 'rarete': 'commune', 'nouvelle': false}),
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
      walletProvider.overrideWith((ref) async => const Wallet(pieces: 480, fragments: 120)),
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
      defisServiceProvider.overrideWithValue(_FakeDefis(_defisSample)),
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

// --- Vitrine -----------------------------------------------------------------

class _MemoryVitrine implements VitrineStore {
  List<String?> slots = List<String?>.filled(kVitrineSlots, null);
  int saves = 0;

  @override
  Future<List<String?>> load() async => [...slots];

  @override
  Future<void> save(List<String?> next) async {
    saves++;
    slots = [...next];
  }
}

final _vitrineOwned = [
  ..._owned,
  OwnedCard({'id': 'o2', 'card_id': 'ed:2', 'variant_id': 'ed:BASE:base', 'origine': 'booster'}),
  OwnedCard({'id': 'o3', 'card_id': 'ed:1', 'variant_id': 'ed:BASE:superfractor', 'numero_serie': 1, 'tirage': 1, 'origine': 'booster'}),
];

List<Override> _vitrineOverrides(_MemoryVitrine store) => [
      ..._overrides(owned: _vitrineOwned),
      vitrineStoreProvider.overrideWithValue(store),
    ];

// --- Atelier -----------------------------------------------------------------

class _FakeAtelier implements AtelierService {
  final recycled = <List<String>>[];
  final crafted = <(String, String)>[];
  final protected = <(String, bool)>[];

  @override
  Future<RecycleResult> recycle(List<String> ownedIds) async {
    recycled.add(ownedIds);
    return RecycleResult(cards: ownedIds.length, gained: ownedIds.length * 5, fragments: 125);
  }

  @override
  Future<void> craft(String cardId, String variantId) async => crafted.add((cardId, variantId));

  @override
  Future<void> protect(String ownedId, bool protect) async => protected.add((ownedId, protect));
}

OwnedCard _copy(String id, String card, String variant, {int? serial, bool locked = false, int day = 1}) => OwnedCard({
      'id': id,
      'card_id': card,
      'variant_id': variant,
      'numero_serie': serial,
      'tirage': serial == null ? null : 50,
      'verrouillee': locked,
      'origine': 'booster',
      'obtenue_le': '2026-10-0${day}T10:00:00Z',
    });

// --- Défis -------------------------------------------------------------------

class _FakeDefis implements DefisService {
  _FakeDefis(this.defis);
  List<Defi> defis;
  final claimed = <String>[];

  @override
  Future<List<Defi>> load() async => defis;

  @override
  Future<int> claim(String id) async {
    claimed.add(id);
    defis = [
      for (final d in defis)
        d.id == id ? _defi(d.id, d.periode, d.progression, d.objectif, d.pieces, recupere: true) : d,
    ];
    return 520;
  }
}

Defi _defi(String id, String periode, int progression, int objectif, int pieces, {bool recupere = false}) => Defi({
      'modele_id': id,
      'periode': periode,
      'type': id,
      'objectif': objectif,
      'pieces': pieces,
      'libelle': {'fr': 'Défi $id', 'en': 'Challenge $id'},
      'progression': progression,
      'recupere': recupere,
      'fin': DateTime.now().add(Duration(hours: periode == 'jour' ? 5 : 80)).toUtc().toIso8601String(),
    });

final _defisSample = [
  _defi('connexion', 'jour', 1, 1, 20),
  _defi('boosters', 'jour', 1, 3, 55),
  _defi('rares', 'jour', 2, 2, 45, recupere: true),
  _defi('semaine', 'semaine', 4, 12, 200),
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
    expect(find.text('Touche ou glisse pour révéler'), findsOneWidget);

    // Première carte : commune, nouvelle
    await tester.tap(find.byKey(const Key('booster-reveal')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('COMMUNE'), findsOneWidget);
    expect(find.text('NOUVELLE'), findsOneWidget);
    expect(find.text('ZHANG WEILI'), findsOneWidget);

    // Suivante : la carte révélée s'envole au toucher
    await tester.tap(find.byKey(const Key('booster-reveal')));
    await _frames(tester, 7);
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

  test('Écran d’entrée : le flottement des cartes raccorde sans saut quand la boucle repart', () {
    for (final phase in [0.0, 0.18, 0.35, 0.47, 0.62, 0.81]) {
      expect((cardFloat(0, phase) - cardFloat(1, phase)).distance, lessThan(1e-9));
      expect((cardWobble(0, phase) - cardWobble(1, phase)).abs(), lessThan(1e-9));
      // Mouvement continu : pas de grand écart entre deux images (60 i/s, boucle de 24 s)
      for (var k = 0; k < 1440; k++) {
        final a = k / 1440, b = (k + 1) / 1440;
        expect((cardFloat(a, phase) - cardFloat(b, phase)).distance, lessThan(0.2));
      }
    }
  });

  test('Barre de navigation : icônes seules', () {
    expect(buildTheme().navigationBarTheme.labelBehavior, NavigationDestinationLabelBehavior.alwaysHide);
  });

  testWidgets('Ouverture : glisser dans les 4 directions fait passer la carte, une carte cachée se révèle d’abord',
      (tester) async {
    _phoneScreen(tester);
    final fake = _FakeBoosters(testMode: true, count: 6);
    await tester.pumpWidget(_wrap(
      const BoosterOpeningScreen(typeId: 'saison-2026:standard', useSensors: false),
      overrides: _boosterOverrides(fake),
      locale: const Locale('fr'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.byKey(const Key('booster-tear')), const Offset(320, 0));
    await _frames(tester, 10);
    expect(find.text('1/6'), findsOneWidget);

    final card = find.byKey(const Key('booster-reveal'));
    // Face cachée : un glissement la retourne sans la faire passer
    await tester.drag(card, const Offset(-260, 0));
    await _frames(tester, 10);
    expect(find.text('1/6'), findsOneWidget);
    expect(find.text('COMMUNE'), findsOneWidget);

    // Révélée : chaque direction fait passer à la suivante
    var expected = 2;
    for (final move in const [Offset(-300, 0), Offset(300, 0), Offset(0, -400), Offset(0, 400)]) {
      await tester.drag(card, move);
      await _frames(tester, 8);
      expect(find.text('$expected/6'), findsOneWidget, reason: 'glissement $move');
      // Révéler la suivante d'un toucher
      await tester.tap(card);
      await _frames(tester, 10);
      expected++;
    }
    // Un petit glissement ne suffit pas : la carte revient en place
    await tester.drag(card, const Offset(30, 0));
    await _frames(tester, 8);
    expect(find.text('5/6'), findsOneWidget);
    // Toucher une carte révélée la fait passer aussi
    await tester.tap(card);
    await _frames(tester, 8);
    expect(find.text('6/6'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Vitrine : exposer via le sélecteur (plus rares d’abord), réorganiser, retirer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneScreen(tester);
    final store = _MemoryVitrine();
    await tester.pumpWidget(_wrap(const VitrineScreen(), overrides: _vitrineOverrides(store), locale: const Locale('fr')));
    await _frames(tester, 3);
    expect(find.text('Ta vitrine est vide. Touche un emplacement pour exposer une carte.'), findsOneWidget);

    // Place d'honneur : le sélecteur s'ouvre, la Mythique (SuperFractor) en premier
    await tester.tap(find.byKey(const Key('vitrine-slot-0')));
    await _frames(tester, 6);
    expect(find.text('Choisir une carte'), findsOneWidget);
    final first = tester.getTopLeft(find.byKey(const Key('pick-o3')));
    final second = tester.getTopLeft(find.byKey(const Key('pick-o1')));
    expect(first.dx < second.dx || first.dy < second.dy, isTrue, reason: 'Mythique avant Épique');
    await tester.tap(find.byKey(const Key('pick-o3')));
    await _frames(tester, 6);
    expect(store.slots[0], 'o3');

    // Deuxième emplacement : une carte déjà exposée n'est plus proposée
    await tester.tap(find.byKey(const Key('vitrine-slot-1')));
    await _frames(tester, 6);
    expect(find.byKey(const Key('pick-o3')), findsNothing);
    await tester.tap(find.byKey(const Key('pick-o2')));
    await _frames(tester, 6);
    expect(store.slots.sublist(0, 2), ['o3', 'o2']);

    // Glisser-déposer : l'emplacement 1 vers la place d'honneur
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('vitrine-slot-1'))));
    await tester.pump(const Duration(milliseconds: 700));
    await g.moveTo(tester.getCenter(find.byKey(const Key('vitrine-slot-0'))));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await _frames(tester, 4);
    expect(store.slots.sublist(0, 2), ['o2', 'o3']);

    // Retirer en mode « Modifier »
    await tester.tap(find.byKey(const Key('vitrine-edit')));
    await _frames(tester, 2);
    await tester.tap(find.byKey(const Key('vitrine-remove-1')));
    await _frames(tester, 4);
    expect(store.slots.sublist(0, 2), ['o2', null]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Vitrine : bouton de la fiche carte (exposer, retirer, vitrine pleine)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _MemoryVitrine();
    Widget button() => _wrap(
          const Scaffold(body: Center(child: VitrineToggleButton(cardId: 'ed:1'))),
          overrides: _vitrineOverrides(store),
          locale: const Locale('fr'),
        );
    await tester.pumpWidget(button());
    await _frames(tester, 2);
    expect(find.text('Exposer dans ma vitrine'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vitrine-toggle')));
    await _frames(tester, 3);
    // Sans exemplaire précisé : le plus rare (SuperFractor) est exposé
    expect(store.slots[0], 'o3');
    expect(find.text('Retirer de ma vitrine'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vitrine-toggle')));
    await _frames(tester, 3);
    expect(store.slots.nonNulls, isEmpty);

    // Vitrine pleine
    store.slots = List<String?>.generate(kVitrineSlots, (i) => 'x$i');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(button());
    await _frames(tester, 2);
    await tester.tap(find.byKey(const Key('vitrine-toggle')));
    await _frames(tester, 3);
    expect(find.text('Vitrine pleine : retire d’abord une carte.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  test('Atelier : doublons recyclables (même règle que le serveur)', () {
    final owned = [
      _copy('a1', 'ed:2', 'ed:BASE:base', day: 1),
      _copy('a2', 'ed:2', 'ed:BASE:base', day: 2),
      _copy('a3', 'ed:2', 'ed:BASE:base', day: 3),
      _copy('b1', 'ed:1', 'ed:BASE:base'), // exemplaire unique : jamais recyclé
      _copy('c1', 'ed:1', 'ed:BASE:gold-refractor', serial: 3),
      _copy('c2', 'ed:1', 'ed:BASE:gold-refractor', serial: 4), // numérotées : jamais
      _copy('d1', 'ed:2', 'ed:BASE:superfractor', locked: true),
      _copy('d2', 'ed:2', 'ed:BASE:superfractor'), // la protégée compte comme l'exemplaire gardé
      _copy('e1', 'ed:1', 'ed:BASE:superfractor'),
      _copy('e2', 'ed:1', 'ed:BASE:superfractor'), // exposée en vitrine : gardée
    ];
    final dupes = recyclableDuplicates(owned: owned, variants: _variants, exposed: {'e2'}, rates: FragmentRates.fallback);
    expect(dupes.map((d) => d.owned.id).toSet(), {'a2', 'a3', 'd2', 'e1'});
    expect(dupes.firstWhere((d) => d.owned.id == 'a2').gain, 5);
    expect(dupes.firstWhere((d) => d.owned.id == 'd2').gain, 1600);
    // Fabrication : numérotée impossible, base = 5 × 6
    expect(FragmentRates.fallback.craftCost(_variants['ed:BASE:base']!), 30);
    expect(FragmentRates.fallback.craftCost(_variants['ed:BASE:gold-refractor']!), isNull);
  });

  testWidgets('Atelier : recycler tous les doublons après confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneScreen(tester);
    final fake = _FakeAtelier();
    final owned = [_copy('a1', 'ed:2', 'ed:BASE:base', day: 1), _copy('a2', 'ed:2', 'ed:BASE:base', day: 2), _copy('a3', 'ed:2', 'ed:BASE:base', day: 3)];
    await tester.pumpWidget(_wrap(
      const Scaffold(body: AtelierView()),
      overrides: [
        ..._overrides(owned: owned),
        atelierServiceProvider.overrideWithValue(fake),
        fragmentRatesProvider.overrideWith((ref) async => FragmentRates.fallback),
        walletProvider.overrideWith((ref) async => const Wallet(pieces: 480, fragments: 120)),
        vitrineStoreProvider.overrideWithValue(_MemoryVitrine()),
      ],
      locale: const Locale('fr'),
    ));
    await _frames(tester, 3);
    expect(find.text('120 fragments'), findsOneWidget);
    expect(find.text('2 doublons · +10 fragments'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atelier-recycle-all')));
    await _frames(tester, 4);
    expect(find.text('Recycler 2 doublons ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atelier-confirm')));
    await _frames(tester, 4);
    expect(fake.recycled.single.toSet(), {'a2', 'a3'});
    expect(find.text('+10 fragments (2 cartes recyclées)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Atelier : fabriquer depuis la fiche (assez ou pas assez de fragments)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fake = _FakeAtelier();
    final view = CardView(card: _cards[1], variant: _variants['ed:BASE:base']!, fighters: [_fighters[1]], edition: _edition, series: _series);
    Widget screen(int fragments) => _wrap(
          Scaffold(body: Center(child: CardAtelierActions(view: view))),
          overrides: [
            ..._overrides(owned: const []),
            atelierServiceProvider.overrideWithValue(fake),
            fragmentRatesProvider.overrideWith((ref) async => FragmentRates.fallback),
            walletProvider.overrideWith((ref) async => Wallet(pieces: 0, fragments: fragments)),
            vitrineStoreProvider.overrideWithValue(_MemoryVitrine()),
          ],
          locale: const Locale('fr'),
        );
    await tester.pumpWidget(screen(10));
    await _frames(tester, 2);
    expect(find.text('Fabriquer · 30 fragments'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('atelier-craft'))).onPressed, isNull,
        reason: '10 fragments < 30');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen(100));
    await _frames(tester, 2);
    await tester.tap(find.byKey(const Key('atelier-craft')));
    await _frames(tester, 3);
    await tester.tap(find.byKey(const Key('atelier-confirm')));
    await _frames(tester, 3);
    expect(fake.crafted, [('ed:2', 'ed:BASE:base')]);
    expect(find.text('Carte fabriquée et ajoutée à ta collection.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Défis : du jour et de la semaine, progression, récupérer une récompense', (tester) async {
    _bigScreen(tester);
    final fake = _FakeDefis([..._defisSample]);
    await tester.pumpWidget(_wrap(
      const DefisScreen(),
      overrides: [..._overrides(), defisServiceProvider.overrideWithValue(fake)],
      locale: const Locale('fr'),
    ));
    await _frames(tester, 6);
    expect(find.text('AUJOURD’HUI'), findsOneWidget);
    expect(find.text('CETTE SEMAINE'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('4/12'), findsOneWidget);
    expect(find.text('Récupéré'), findsOneWidget);
    expect(find.textContaining('Renouvelés dans'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('defi-claim-connexion')));
    await _frames(tester, 4);
    expect(fake.claimed, ['connexion']);
    expect(find.text('+20 pièces'), findsOneWidget);
    expect(find.text('Récupéré'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Accueil : pastille du nombre de défis à récupérer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneScreen(tester);
    await tester.pumpWidget(
        _wrap(const HomeScreen(useSensors: false), overrides: _boosterOverrides(_FakeBoosters()), locale: const Locale('fr')));
    await _frames(tester, 4);
    final chip = find.byKey(const Key('home-defis'));
    expect(find.descendant(of: chip, matching: find.text('Défis')), findsOneWidget);
    expect(find.descendant(of: chip, matching: find.text('1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
