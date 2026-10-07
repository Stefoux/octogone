import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Octogone'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @errorWithMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String errorWithMessage(String message);

  /// No description provided for @toVerify.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier : {fields}'**
  String toVerify(String fields);

  /// No description provided for @missingConfig.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Supabase manquante.\n\nCompile avec :\nflutter run --dart-define-from-file=config/app.json\n\n(fichier généré par scripts/supabase_setup.sh)'**
  String get missingConfig;

  /// No description provided for @authTagline.
  ///
  /// In fr, this message translates to:
  /// **'Cartes de combattants entre amis'**
  String get authTagline;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Créer un compte'**
  String get noAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get passwordRequired;

  /// No description provided for @signupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get signupTitle;

  /// No description provided for @pseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get pseudo;

  /// No description provided for @pseudoMin.
  ///
  /// In fr, this message translates to:
  /// **'3 caractères minimum'**
  String get pseudoMin;

  /// No description provided for @pseudoChars.
  ///
  /// In fr, this message translates to:
  /// **'Lettres, chiffres, espace, « _ », « - » ou « . »'**
  String get pseudoChars;

  /// No description provided for @passwordMinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe (8 caractères min.)'**
  String get passwordMinLabel;

  /// No description provided for @passwordMin.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get passwordMin;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirme le mot de passe'**
  String get confirmPassword;

  /// No description provided for @passwordsDiffer.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe diffèrent'**
  String get passwordsDiffer;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createAccount;

  /// No description provided for @pseudoTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est déjà pris.'**
  String get pseudoTaken;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get errInvalidCredentials;

  /// No description provided for @errAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet email.'**
  String get errAlreadyRegistered;

  /// No description provided for @errPasswordShort.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop court (8 caractères minimum).'**
  String get errPasswordShort;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Email non confirmé.'**
  String get errEmailNotConfirmed;

  /// No description provided for @errRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives : réessaie dans quelques minutes.'**
  String get errRateLimit;

  /// No description provided for @errNoInternet.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get errNoInternet;

  /// No description provided for @errUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue : {message}'**
  String errUnexpected(String message);

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get navAlbum;

  /// No description provided for @navFighters.
  ///
  /// In fr, this message translates to:
  /// **'Combattants'**
  String get navFighters;

  /// No description provided for @navFight.
  ///
  /// In fr, this message translates to:
  /// **'Combat'**
  String get navFight;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @helloUser.
  ///
  /// In fr, this message translates to:
  /// **'Salut {pseudo} !'**
  String helloUser(String pseudo);

  /// No description provided for @sync.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get sync;

  /// No description provided for @syncRunning.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation du contenu…'**
  String get syncRunning;

  /// No description provided for @syncOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : contenu en cache'**
  String get syncOffline;

  /// No description provided for @syncUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'À jour ({date})'**
  String syncUpToDate(String date);

  /// No description provided for @syncUpToDateReceived.
  ///
  /// In fr, this message translates to:
  /// **'À jour ({date}) · {count} éléments reçus'**
  String syncUpToDateReceived(String date, int count);

  /// No description provided for @syncWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente de synchronisation'**
  String get syncWaiting;

  /// No description provided for @statFighters.
  ///
  /// In fr, this message translates to:
  /// **'combattants'**
  String get statFighters;

  /// No description provided for @statChampions.
  ///
  /// In fr, this message translates to:
  /// **'champions'**
  String get statChampions;

  /// No description provided for @statEditions.
  ///
  /// In fr, this message translates to:
  /// **'éditions'**
  String get statEditions;

  /// No description provided for @statMyCards.
  ///
  /// In fr, this message translates to:
  /// **'cartes'**
  String get statMyCards;

  /// No description provided for @browseEditions.
  ///
  /// In fr, this message translates to:
  /// **'Mon album'**
  String get browseEditions;

  /// No description provided for @browseEditionsSub.
  ///
  /// In fr, this message translates to:
  /// **'Classeurs par édition, complétion, filtres'**
  String get browseEditionsSub;

  /// No description provided for @allFighters.
  ///
  /// In fr, this message translates to:
  /// **'Tous les combattants'**
  String get allFighters;

  /// No description provided for @allFightersSub.
  ///
  /// In fr, this message translates to:
  /// **'Stats réelles et stats de jeu'**
  String get allFightersSub;

  /// No description provided for @dailyBooster.
  ///
  /// In fr, this message translates to:
  /// **'Booster quotidien'**
  String get dailyBooster;

  /// No description provided for @comingPhase3.
  ///
  /// In fr, this message translates to:
  /// **'Arrive avec la phase 3'**
  String get comingPhase3;

  /// No description provided for @welcomePack.
  ///
  /// In fr, this message translates to:
  /// **'Pack de bienvenue'**
  String get welcomePack;

  /// No description provided for @welcomePackSub.
  ///
  /// In fr, this message translates to:
  /// **'15 cartes offertes, dont des rares'**
  String get welcomePackSub;

  /// No description provided for @welcomePackOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get welcomePackOpen;

  /// No description provided for @welcomePackReceived.
  ///
  /// In fr, this message translates to:
  /// **'Tu as reçu {count} cartes !'**
  String welcomePackReceived(int count);

  /// No description provided for @welcomePackAlready.
  ///
  /// In fr, this message translates to:
  /// **'Pack de bienvenue déjà reçu'**
  String get welcomePackAlready;

  /// No description provided for @effectsShowcase.
  ///
  /// In fr, this message translates to:
  /// **'Galerie des effets'**
  String get effectsShowcase;

  /// No description provided for @effectsShowcaseSub.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les raretés en aperçu'**
  String get effectsShowcaseSub;

  /// No description provided for @fightersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Combattants'**
  String get fightersTitle;

  /// No description provided for @searchFighters.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un nom ou un surnom'**
  String get searchFighters;

  /// No description provided for @champions.
  ///
  /// In fr, this message translates to:
  /// **'Champions'**
  String get champions;

  /// No description provided for @downloadingFighters.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement des combattants…'**
  String get downloadingFighters;

  /// No description provided for @downloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de télécharger le contenu. Vérifie ta connexion.'**
  String get downloadFailed;

  /// No description provided for @noFighters.
  ///
  /// In fr, this message translates to:
  /// **'Aucun combattant pour l’instant.'**
  String get noFighters;

  /// No description provided for @fighterNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Combattant introuvable'**
  String get fighterNotFound;

  /// No description provided for @unknownCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays inconnu'**
  String get unknownCountry;

  /// No description provided for @categoryToVerify.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie à vérifier'**
  String get categoryToVerify;

  /// No description provided for @recordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Palmarès {record}'**
  String recordLabel(String record);

  /// No description provided for @tagChampion.
  ///
  /// In fr, this message translates to:
  /// **'Champion'**
  String get tagChampion;

  /// No description provided for @tagChampionF.
  ///
  /// In fr, this message translates to:
  /// **'Championne'**
  String get tagChampionF;

  /// No description provided for @tagFormerChampion.
  ///
  /// In fr, this message translates to:
  /// **'Ancien champion'**
  String get tagFormerChampion;

  /// No description provided for @tagFormerChampionF.
  ///
  /// In fr, this message translates to:
  /// **'Ancienne championne'**
  String get tagFormerChampionF;

  /// No description provided for @tagRetired.
  ///
  /// In fr, this message translates to:
  /// **'Retraité'**
  String get tagRetired;

  /// No description provided for @tagRetiredF.
  ///
  /// In fr, this message translates to:
  /// **'Retraitée'**
  String get tagRetiredF;

  /// No description provided for @gameStats.
  ///
  /// In fr, this message translates to:
  /// **'Stats de jeu'**
  String get gameStats;

  /// No description provided for @gameStatsNote.
  ///
  /// In fr, this message translates to:
  /// **'Calculées à partir des statistiques réelles ci-dessous.'**
  String get gameStatsNote;

  /// No description provided for @ufcStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques UFC'**
  String get ufcStats;

  /// No description provided for @sigStrikesPerMin.
  ///
  /// In fr, this message translates to:
  /// **'Frappes significatives / min'**
  String get sigStrikesPerMin;

  /// No description provided for @strikeAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision de frappe'**
  String get strikeAccuracy;

  /// No description provided for @strikesAbsorbed.
  ///
  /// In fr, this message translates to:
  /// **'Frappes encaissées / min'**
  String get strikesAbsorbed;

  /// No description provided for @strikeDefense.
  ///
  /// In fr, this message translates to:
  /// **'Défense de frappe'**
  String get strikeDefense;

  /// No description provided for @takedownsPer15.
  ///
  /// In fr, this message translates to:
  /// **'Takedowns / 15 min'**
  String get takedownsPer15;

  /// No description provided for @takedownAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision des takedowns'**
  String get takedownAccuracy;

  /// No description provided for @takedownDefense.
  ///
  /// In fr, this message translates to:
  /// **'Défense de takedown'**
  String get takedownDefense;

  /// No description provided for @subsPer15.
  ///
  /// In fr, this message translates to:
  /// **'Tentatives de soumission / 15 min'**
  String get subsPer15;

  /// No description provided for @knockdownsPer15.
  ///
  /// In fr, this message translates to:
  /// **'Knockdowns / 15 min'**
  String get knockdownsPer15;

  /// No description provided for @avgFightTime.
  ///
  /// In fr, this message translates to:
  /// **'Durée moyenne d’un combat'**
  String get avgFightTime;

  /// No description provided for @minutesSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{min} min {sec}'**
  String minutesSeconds(int min, String sec);

  /// No description provided for @proRecord.
  ///
  /// In fr, this message translates to:
  /// **'Palmarès professionnel'**
  String get proRecord;

  /// No description provided for @wins.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In fr, this message translates to:
  /// **'Défaites'**
  String get losses;

  /// No description provided for @draws.
  ///
  /// In fr, this message translates to:
  /// **'Nuls'**
  String get draws;

  /// No description provided for @noContests.
  ///
  /// In fr, this message translates to:
  /// **'Sans décision'**
  String get noContests;

  /// No description provided for @methodBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'{total}  (KO {ko} · Sou. {sub} · Déc. {dec})'**
  String methodBreakdown(String total, String ko, String sub, String dec);

  /// No description provided for @ufcFights.
  ///
  /// In fr, this message translates to:
  /// **'Combats à l’UFC'**
  String get ufcFights;

  /// No description provided for @ufcFightsValue.
  ///
  /// In fr, this message translates to:
  /// **'{total} ({wins} V – {losses} D)'**
  String ufcFightsValue(String total, String wins, String losses);

  /// No description provided for @bonusFotn.
  ///
  /// In fr, this message translates to:
  /// **'Bonus « Combat de la soirée »'**
  String get bonusFotn;

  /// No description provided for @bonusPotn.
  ///
  /// In fr, this message translates to:
  /// **'Bonus « Performance de la soirée »'**
  String get bonusPotn;

  /// No description provided for @fiveRoundDecisions.
  ///
  /// In fr, this message translates to:
  /// **'Victoires par décision en 5 rounds'**
  String get fiveRoundDecisions;

  /// No description provided for @distinctions.
  ///
  /// In fr, this message translates to:
  /// **'Distinctions'**
  String get distinctions;

  /// No description provided for @cardsCount.
  ///
  /// In fr, this message translates to:
  /// **'Cartes ({count})'**
  String cardsCount(int count);

  /// No description provided for @albumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get albumTitle;

  /// No description provided for @realEditions.
  ///
  /// In fr, this message translates to:
  /// **'Éditions réelles'**
  String get realEditions;

  /// No description provided for @originalEditions.
  ///
  /// In fr, this message translates to:
  /// **'Éditions originales'**
  String get originalEditions;

  /// No description provided for @noEditions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune édition en cache pour l’instant.'**
  String get noEditions;

  /// No description provided for @editionCards.
  ///
  /// In fr, this message translates to:
  /// **'{count} cartes'**
  String editionCards(int count);

  /// No description provided for @originalCreation.
  ///
  /// In fr, this message translates to:
  /// **'création originale'**
  String get originalCreation;

  /// No description provided for @releaseDate.
  ///
  /// In fr, this message translates to:
  /// **'Sortie : {date}'**
  String releaseDate(String date);

  /// No description provided for @seriesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} séries'**
  String seriesCount(int count);

  /// No description provided for @parallels.
  ///
  /// In fr, this message translates to:
  /// **'Parallèles'**
  String get parallels;

  /// No description provided for @numberedSeries.
  ///
  /// In fr, this message translates to:
  /// **'numérotée /{n}'**
  String numberedSeries(int n);

  /// No description provided for @oddsLabel.
  ///
  /// In fr, this message translates to:
  /// **'cote {odds}'**
  String oddsLabel(String odds);

  /// No description provided for @checklistSources.
  ///
  /// In fr, this message translates to:
  /// **'Sources de la checklist'**
  String get checklistSources;

  /// No description provided for @seriesBase.
  ///
  /// In fr, this message translates to:
  /// **'Base'**
  String get seriesBase;

  /// No description provided for @seriesAutographs.
  ///
  /// In fr, this message translates to:
  /// **'Autographes'**
  String get seriesAutographs;

  /// No description provided for @seriesRelics.
  ///
  /// In fr, this message translates to:
  /// **'Reliques'**
  String get seriesRelics;

  /// No description provided for @seriesMoments.
  ///
  /// In fr, this message translates to:
  /// **'Moments Historiques'**
  String get seriesMoments;

  /// No description provided for @seriesCelebrations.
  ///
  /// In fr, this message translates to:
  /// **'Célébrations'**
  String get seriesCelebrations;

  /// No description provided for @seriesInsert.
  ///
  /// In fr, this message translates to:
  /// **'Insert'**
  String get seriesInsert;

  /// No description provided for @completion.
  ///
  /// In fr, this message translates to:
  /// **'{owned}/{total} · {pct} %'**
  String completion(int owned, int total, int pct);

  /// No description provided for @pageOf.
  ///
  /// In fr, this message translates to:
  /// **'Page {page}/{total}'**
  String pageOf(int page, int total);

  /// No description provided for @filterAllRarities.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les raretés'**
  String get filterAllRarities;

  /// No description provided for @filterAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les catégories'**
  String get filterAllCategories;

  /// No description provided for @filterOwnedOnly.
  ///
  /// In fr, this message translates to:
  /// **'Possédées'**
  String get filterOwnedOnly;

  /// No description provided for @filterSearchFighter.
  ///
  /// In fr, this message translates to:
  /// **'Combattant…'**
  String get filterSearchFighter;

  /// No description provided for @checklistView.
  ///
  /// In fr, this message translates to:
  /// **'Checklist'**
  String get checklistView;

  /// No description provided for @binderView.
  ///
  /// In fr, this message translates to:
  /// **'Classeur'**
  String get binderView;

  /// No description provided for @notOwned.
  ///
  /// In fr, this message translates to:
  /// **'Non possédée'**
  String get notOwned;

  /// No description provided for @ownedCopies.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 exemplaire} other{{count} exemplaires}}'**
  String ownedCopies(int count);

  /// No description provided for @emptySlot.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement vide'**
  String get emptySlot;

  /// No description provided for @cardFlipHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche la carte pour la retourner'**
  String get cardFlipHint;

  /// No description provided for @cardTiltHint.
  ///
  /// In fr, this message translates to:
  /// **'Incline ton téléphone'**
  String get cardTiltHint;

  /// No description provided for @cardRecord.
  ///
  /// In fr, this message translates to:
  /// **'Palmarès'**
  String get cardRecord;

  /// No description provided for @cardSignatureMove.
  ///
  /// In fr, this message translates to:
  /// **'Coup signature'**
  String get cardSignatureMove;

  /// No description provided for @cardSignatureLocked.
  ///
  /// In fr, this message translates to:
  /// **'Débloqué à partir d’Épique'**
  String get cardSignatureLocked;

  /// No description provided for @cardHighlights.
  ///
  /// In fr, this message translates to:
  /// **'Faits marquants'**
  String get cardHighlights;

  /// No description provided for @cardStatBonus.
  ///
  /// In fr, this message translates to:
  /// **'Bonus de rareté +{n}'**
  String cardStatBonus(int n);

  /// No description provided for @cardSerial.
  ///
  /// In fr, this message translates to:
  /// **'{serial}/{run}'**
  String cardSerial(int serial, int run);

  /// No description provided for @cardPrintRun.
  ///
  /// In fr, this message translates to:
  /// **'Tirage /{run}'**
  String cardPrintRun(int run);

  /// No description provided for @cardRookie.
  ///
  /// In fr, this message translates to:
  /// **'Recrue'**
  String get cardRookie;

  /// No description provided for @cardNumberInSeries.
  ///
  /// In fr, this message translates to:
  /// **'{number}/{total}'**
  String cardNumberInSeries(String number, int total);

  /// No description provided for @showcaseIntro.
  ///
  /// In fr, this message translates to:
  /// **'Chaque rareté a son effet. Touche une carte pour l’ouvrir en grand, puis incline ton téléphone.'**
  String get showcaseIntro;

  /// No description provided for @showcasePreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get showcasePreview;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du profil…'**
  String get profileLoading;

  /// No description provided for @profileOffline.
  ///
  /// In fr, this message translates to:
  /// **'Profil indisponible hors ligne'**
  String get profileOffline;

  /// No description provided for @administrator.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get administrator;

  /// No description provided for @myFriendCode.
  ///
  /// In fr, this message translates to:
  /// **'Mon code ami'**
  String get myFriendCode;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @friendCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code ami copié'**
  String get friendCodeCopied;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @creditsAndSources.
  ///
  /// In fr, this message translates to:
  /// **'Crédits et sources'**
  String get creditsAndSources;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @syncContent.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser le contenu'**
  String get syncContent;

  /// No description provided for @syncContentSub.
  ///
  /// In fr, this message translates to:
  /// **'Combattants, éditions, images'**
  String get syncContentSub;

  /// No description provided for @syncFailed.
  ///
  /// In fr, this message translates to:
  /// **'Dernière tentative échouée (hors ligne ?)'**
  String get syncFailed;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @versionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Octogone · version {version}'**
  String versionLabel(String version);

  /// No description provided for @creditsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Crédits'**
  String get creditsTitle;

  /// No description provided for @creditsDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Application personnelle, non commerciale et non officielle. Aucun logo officiel : les noms d’éditions apparaissent en texte et les cadres des cartes sont des créations originales.'**
  String get creditsDisclaimer;

  /// No description provided for @dataSources.
  ///
  /// In fr, this message translates to:
  /// **'Sources des données'**
  String get dataSources;

  /// No description provided for @srcStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques officielles des combattants'**
  String get srcStats;

  /// No description provided for @srcRecords.
  ///
  /// In fr, this message translates to:
  /// **'Palmarès détaillés, distinctions'**
  String get srcRecords;

  /// No description provided for @srcNationality.
  ///
  /// In fr, this message translates to:
  /// **'Nationalité, date de naissance'**
  String get srcNationality;

  /// No description provided for @srcChecklists.
  ///
  /// In fr, this message translates to:
  /// **'Checklists des éditions réelles'**
  String get srcChecklists;

  /// No description provided for @srcChecklistCheck.
  ///
  /// In fr, this message translates to:
  /// **'Recoupement des checklists'**
  String get srcChecklistCheck;

  /// No description provided for @srcPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get srcPhotos;

  /// No description provided for @srcPhotosWho.
  ///
  /// In fr, this message translates to:
  /// **'Wikimedia Commons (licences libres)'**
  String get srcPhotosWho;

  /// No description provided for @srcFont.
  ///
  /// In fr, this message translates to:
  /// **'Polices Oswald et Barlow (SIL Open Font License)'**
  String get srcFont;

  /// No description provided for @srcSounds.
  ///
  /// In fr, this message translates to:
  /// **'Effets sonores'**
  String get srcSounds;

  /// No description provided for @srcSoundsWho.
  ///
  /// In fr, this message translates to:
  /// **'Synthétisés pour Octogone (aucun son externe)'**
  String get srcSoundsWho;

  /// No description provided for @photosCount.
  ///
  /// In fr, this message translates to:
  /// **'Photos ({count})'**
  String photosCount(int count);

  /// No description provided for @noPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo synchronisée.'**
  String get noPhotos;

  /// No description provided for @photoAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Auteur : {name}'**
  String photoAuthor(String name);

  /// No description provided for @photoLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence : {name}'**
  String photoLicense(String name);

  /// No description provided for @fightComing.
  ///
  /// In fr, this message translates to:
  /// **'Le combat tactique arrive en phase 4.'**
  String get fightComing;

  /// No description provided for @rarityCommune.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get rarityCommune;

  /// No description provided for @rarityPeuCommune.
  ///
  /// In fr, this message translates to:
  /// **'Peu commune'**
  String get rarityPeuCommune;

  /// No description provided for @rarityRare.
  ///
  /// In fr, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpique.
  ///
  /// In fr, this message translates to:
  /// **'Épique'**
  String get rarityEpique;

  /// No description provided for @rarityLegendaire.
  ///
  /// In fr, this message translates to:
  /// **'Légendaire'**
  String get rarityLegendaire;

  /// No description provided for @rarityMythique.
  ///
  /// In fr, this message translates to:
  /// **'Mythique'**
  String get rarityMythique;

  /// No description provided for @effectAcier.
  ///
  /// In fr, this message translates to:
  /// **'Acier d’Octogone'**
  String get effectAcier;

  /// No description provided for @effectNeon.
  ///
  /// In fr, this message translates to:
  /// **'Néon Main Event'**
  String get effectNeon;

  /// No description provided for @effectFaceAFace.
  ///
  /// In fr, this message translates to:
  /// **'Face-à-Face'**
  String get effectFaceAFace;

  /// No description provided for @effectCicatrice.
  ///
  /// In fr, this message translates to:
  /// **'Cicatrice'**
  String get effectCicatrice;

  /// No description provided for @effectOndeDeChoc.
  ///
  /// In fr, this message translates to:
  /// **'Onde de Choc'**
  String get effectOndeDeChoc;

  /// No description provided for @effectCleFatale.
  ///
  /// In fr, this message translates to:
  /// **'Clé Fatale'**
  String get effectCleFatale;

  /// No description provided for @effectCeintureOr.
  ///
  /// In fr, this message translates to:
  /// **'Ceinture d’Or'**
  String get effectCeintureOr;

  /// No description provided for @effectHeritage.
  ///
  /// In fr, this message translates to:
  /// **'Héritage'**
  String get effectHeritage;

  /// No description provided for @effectMoment.
  ///
  /// In fr, this message translates to:
  /// **'Moment Historique'**
  String get effectMoment;

  /// No description provided for @effectTrilogie.
  ///
  /// In fr, this message translates to:
  /// **'Trilogie'**
  String get effectTrilogie;

  /// No description provided for @effectOctogoneNoir.
  ///
  /// In fr, this message translates to:
  /// **'Octogone Noir'**
  String get effectOctogoneNoir;

  /// No description provided for @effectMainLevee.
  ///
  /// In fr, this message translates to:
  /// **'Main Levée'**
  String get effectMainLevee;

  /// No description provided for @wcPailleF.
  ///
  /// In fr, this message translates to:
  /// **'Poids paille (F)'**
  String get wcPailleF;

  /// No description provided for @wcMoucheF.
  ///
  /// In fr, this message translates to:
  /// **'Poids mouche (F)'**
  String get wcMoucheF;

  /// No description provided for @wcCoqF.
  ///
  /// In fr, this message translates to:
  /// **'Poids coq (F)'**
  String get wcCoqF;

  /// No description provided for @wcPlumeF.
  ///
  /// In fr, this message translates to:
  /// **'Poids plume (F)'**
  String get wcPlumeF;

  /// No description provided for @wcMouche.
  ///
  /// In fr, this message translates to:
  /// **'Poids mouche'**
  String get wcMouche;

  /// No description provided for @wcCoq.
  ///
  /// In fr, this message translates to:
  /// **'Poids coq'**
  String get wcCoq;

  /// No description provided for @wcPlume.
  ///
  /// In fr, this message translates to:
  /// **'Poids plume'**
  String get wcPlume;

  /// No description provided for @wcLegers.
  ///
  /// In fr, this message translates to:
  /// **'Poids légers'**
  String get wcLegers;

  /// No description provided for @wcMiMoyens.
  ///
  /// In fr, this message translates to:
  /// **'Poids mi-moyens'**
  String get wcMiMoyens;

  /// No description provided for @wcMoyens.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyens'**
  String get wcMoyens;

  /// No description provided for @wcMiLourds.
  ///
  /// In fr, this message translates to:
  /// **'Poids mi-lourds'**
  String get wcMiLourds;

  /// No description provided for @wcLourds.
  ///
  /// In fr, this message translates to:
  /// **'Poids lourds'**
  String get wcLourds;

  /// No description provided for @statFrappe.
  ///
  /// In fr, this message translates to:
  /// **'Frappe'**
  String get statFrappe;

  /// No description provided for @statPuissance.
  ///
  /// In fr, this message translates to:
  /// **'Puissance'**
  String get statPuissance;

  /// No description provided for @statLutte.
  ///
  /// In fr, this message translates to:
  /// **'Lutte'**
  String get statLutte;

  /// No description provided for @statSoumission.
  ///
  /// In fr, this message translates to:
  /// **'Soumission'**
  String get statSoumission;

  /// No description provided for @statDefense.
  ///
  /// In fr, this message translates to:
  /// **'Défense'**
  String get statDefense;

  /// No description provided for @statCardio.
  ///
  /// In fr, this message translates to:
  /// **'Cardio'**
  String get statCardio;

  /// No description provided for @statMenton.
  ///
  /// In fr, this message translates to:
  /// **'Menton'**
  String get statMenton;

  /// No description provided for @statFrappeShort.
  ///
  /// In fr, this message translates to:
  /// **'FRA'**
  String get statFrappeShort;

  /// No description provided for @statPuissanceShort.
  ///
  /// In fr, this message translates to:
  /// **'PUI'**
  String get statPuissanceShort;

  /// No description provided for @statLutteShort.
  ///
  /// In fr, this message translates to:
  /// **'LUT'**
  String get statLutteShort;

  /// No description provided for @statSoumissionShort.
  ///
  /// In fr, this message translates to:
  /// **'SOU'**
  String get statSoumissionShort;

  /// No description provided for @statDefenseShort.
  ///
  /// In fr, this message translates to:
  /// **'DÉF'**
  String get statDefenseShort;

  /// No description provided for @statCardioShort.
  ///
  /// In fr, this message translates to:
  /// **'CAR'**
  String get statCardioShort;

  /// No description provided for @statMentonShort.
  ///
  /// In fr, this message translates to:
  /// **'MEN'**
  String get statMentonShort;

  /// No description provided for @styleFrappeur.
  ///
  /// In fr, this message translates to:
  /// **'Frappeur'**
  String get styleFrappeur;

  /// No description provided for @styleLutteur.
  ///
  /// In fr, this message translates to:
  /// **'Lutteur'**
  String get styleLutteur;

  /// No description provided for @styleGrappler.
  ///
  /// In fr, this message translates to:
  /// **'Grappler'**
  String get styleGrappler;

  /// No description provided for @styleComplet.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get styleComplet;

  /// No description provided for @boosterOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get boosterOpen;

  /// No description provided for @boosterChooseCollections.
  ///
  /// In fr, this message translates to:
  /// **'Choisir d’autres collections'**
  String get boosterChooseCollections;

  /// No description provided for @boosterCollectionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Collections'**
  String get boosterCollectionsTitle;

  /// No description provided for @boosterCards.
  ///
  /// In fr, this message translates to:
  /// **'{n} cartes'**
  String boosterCards(int n);

  /// No description provided for @boosterStandard.
  ///
  /// In fr, this message translates to:
  /// **'Standard'**
  String get boosterStandard;

  /// No description provided for @boosterPremium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get boosterPremium;

  /// No description provided for @boosterEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get boosterEvent;

  /// No description provided for @boosterTestMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode test : boosters illimités'**
  String get boosterTestMode;

  /// No description provided for @boosterFreeReady.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 booster gratuit prêt} other{{count} boosters gratuits prêts}}'**
  String boosterFreeReady(int count);

  /// No description provided for @boosterNextFree.
  ///
  /// In fr, this message translates to:
  /// **'Prochain booster gratuit dans {time}'**
  String boosterNextFree(String time);

  /// No description provided for @boosterNoFree.
  ///
  /// In fr, this message translates to:
  /// **'Plus de booster gratuit pour l’instant'**
  String get boosterNoFree;

  /// No description provided for @boosterPayWithCoins.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir ce booster pour {price} pièces ?'**
  String boosterPayWithCoins(int price);

  /// No description provided for @boosterPrice.
  ///
  /// In fr, this message translates to:
  /// **'{price} pièces'**
  String boosterPrice(int price);

  /// No description provided for @boosterNotEnoughCoins.
  ///
  /// In fr, this message translates to:
  /// **'Pas assez de pièces.'**
  String get boosterNotEnoughCoins;

  /// No description provided for @boosterUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce booster n’est plus disponible.'**
  String get boosterUnavailable;

  /// No description provided for @boosterOdds.
  ///
  /// In fr, this message translates to:
  /// **'Probabilités'**
  String get boosterOdds;

  /// No description provided for @boosterOddsPerPack.
  ///
  /// In fr, this message translates to:
  /// **'{n} par booster'**
  String boosterOddsPerPack(String n);

  /// No description provided for @boosterOddsOneIn.
  ///
  /// In fr, this message translates to:
  /// **'1 sur {n} boosters'**
  String boosterOddsOneIn(int n);

  /// No description provided for @boosterOddsPercent.
  ///
  /// In fr, this message translates to:
  /// **'{pct} % des boosters'**
  String boosterOddsPercent(int pct);

  /// No description provided for @boosterPity.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une Légendaire tous les {n} boosters.'**
  String boosterPity(int n);

  /// No description provided for @boosterPityLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Garantie au prochain booster au plus tard.} other{Garantie dans {count} boosters au plus tard.}}'**
  String boosterPityLeft(int count);

  /// No description provided for @boosterNumberedNote.
  ///
  /// In fr, this message translates to:
  /// **'Les cartes numérotées (/50, 1/1…) n’existent qu’en nombre limité, pour tous les joueurs réunis.'**
  String get boosterNumberedNote;

  /// No description provided for @boosterTearHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisse le doigt le long du haut pour déchirer'**
  String get boosterTearHint;

  /// No description provided for @boosterTapToReveal.
  ///
  /// In fr, this message translates to:
  /// **'Touche ou glisse pour révéler'**
  String get boosterTapToReveal;

  /// No description provided for @boosterTapForNext.
  ///
  /// In fr, this message translates to:
  /// **'Glisse ou touche pour la suivante'**
  String get boosterTapForNext;

  /// No description provided for @boosterRevealAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout révéler'**
  String get boosterRevealAll;

  /// No description provided for @boosterNew.
  ///
  /// In fr, this message translates to:
  /// **'NOUVELLE'**
  String get boosterNew;

  /// No description provided for @boosterOpenAnother.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir un autre'**
  String get boosterOpenAnother;

  /// No description provided for @boosterDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get boosterDone;

  /// No description provided for @boosterOpening.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture…'**
  String get boosterOpening;

  /// No description provided for @coins.
  ///
  /// In fr, this message translates to:
  /// **'{n} pièces'**
  String coins(int n);

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @settingsSound.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settingsSound;

  /// No description provided for @settingsSoundSub.
  ///
  /// In fr, this message translates to:
  /// **'Déchirure des boosters et révélation des cartes'**
  String get settingsSoundSub;

  /// No description provided for @durationHm.
  ///
  /// In fr, this message translates to:
  /// **'{h} h {m} min'**
  String durationHm(int h, int m);

  /// No description provided for @durationM.
  ///
  /// In fr, this message translates to:
  /// **'{m} min'**
  String durationM(int m);

  /// No description provided for @entryCta.
  ///
  /// In fr, this message translates to:
  /// **'ENTRER DANS L’OCTOGONE'**
  String get entryCta;

  /// No description provided for @homeFeatured.
  ///
  /// In fr, this message translates to:
  /// **'Collection en vedette'**
  String get homeFeatured;

  /// No description provided for @srcPackPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos des sachets'**
  String get srcPackPhotos;

  /// No description provided for @srcPackPhotosWho.
  ///
  /// In fr, this message translates to:
  /// **'Photos officielles des combattants (usage privé)'**
  String get srcPackPhotosWho;

  /// No description provided for @vitrineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma vitrine'**
  String get vitrineTitle;

  /// No description provided for @vitrineSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Expose tes plus belles cartes.'**
  String get vitrineSubtitle;

  /// No description provided for @vitrineEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ta vitrine est vide. Touche un emplacement pour exposer une carte.'**
  String get vitrineEmpty;

  /// No description provided for @vitrineReorderHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long puis glisse pour changer une carte de place.'**
  String get vitrineReorderHint;

  /// No description provided for @vitrineHonor.
  ///
  /// In fr, this message translates to:
  /// **'Place d’honneur'**
  String get vitrineHonor;

  /// No description provided for @vitrineEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get vitrineEdit;

  /// No description provided for @vitrineDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get vitrineDone;

  /// No description provided for @vitrinePickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une carte'**
  String get vitrinePickTitle;

  /// No description provided for @vitrinePickSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un combattant'**
  String get vitrinePickSearch;

  /// No description provided for @vitrinePickEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte à exposer.'**
  String get vitrinePickEmpty;

  /// No description provided for @vitrineAdd.
  ///
  /// In fr, this message translates to:
  /// **'Exposer dans ma vitrine'**
  String get vitrineAdd;

  /// No description provided for @vitrineRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de ma vitrine'**
  String get vitrineRemove;

  /// No description provided for @vitrineAdded.
  ///
  /// In fr, this message translates to:
  /// **'Carte exposée dans ta vitrine.'**
  String get vitrineAdded;

  /// No description provided for @vitrineRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Carte retirée de ta vitrine.'**
  String get vitrineRemoved;

  /// No description provided for @vitrineFull.
  ///
  /// In fr, this message translates to:
  /// **'Vitrine pleine : retire d’abord une carte.'**
  String get vitrineFull;

  /// No description provided for @vitrineCount.
  ///
  /// In fr, this message translates to:
  /// **'{count}/{total}'**
  String vitrineCount(int count, int total);

  /// No description provided for @vitrineSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer la vitrine : {message}'**
  String vitrineSaveError(String message);

  /// No description provided for @atelierTitle.
  ///
  /// In fr, this message translates to:
  /// **'Atelier'**
  String get atelierTitle;

  /// No description provided for @atelierFragments.
  ///
  /// In fr, this message translates to:
  /// **'{n} fragments'**
  String atelierFragments(int n);

  /// No description provided for @atelierRecycleAll.
  ///
  /// In fr, this message translates to:
  /// **'Recycler tous les doublons'**
  String get atelierRecycleAll;

  /// No description provided for @atelierRecycleAllSub.
  ///
  /// In fr, this message translates to:
  /// **'{count} doublons · +{gain} fragments'**
  String atelierRecycleAllSub(int count, int gain);

  /// No description provided for @atelierNoDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'Aucun doublon à recycler pour l’instant.'**
  String get atelierNoDuplicates;

  /// No description provided for @atelierRecycleConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recycler {count} doublons ?'**
  String atelierRecycleConfirmTitle(int count);

  /// No description provided for @atelierRecycleConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tu gagnes {gain} fragments. Tu gardes au moins un exemplaire de chaque carte.'**
  String atelierRecycleConfirm(int gain);

  /// No description provided for @atelierRecycled.
  ///
  /// In fr, this message translates to:
  /// **'+{gain} fragments ({count} cartes recyclées)'**
  String atelierRecycled(int gain, int count);

  /// No description provided for @atelierRecycleOne.
  ///
  /// In fr, this message translates to:
  /// **'Recycler un doublon (+{gain})'**
  String atelierRecycleOne(int gain);

  /// No description provided for @atelierRules.
  ///
  /// In fr, this message translates to:
  /// **'Les cartes numérotées, protégées ou exposées dans la vitrine ne sont jamais recyclées.'**
  String get atelierRules;

  /// No description provided for @atelierCraft.
  ///
  /// In fr, this message translates to:
  /// **'Fabriquer · {cost} fragments'**
  String atelierCraft(int cost);

  /// No description provided for @atelierCraftTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fabriquer cette carte ?'**
  String get atelierCraftTitle;

  /// No description provided for @atelierCraftConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Elle coûte {cost} fragments et rejoint ta collection.'**
  String atelierCraftConfirm(int cost);

  /// No description provided for @atelierCrafted.
  ///
  /// In fr, this message translates to:
  /// **'Carte fabriquée et ajoutée à ta collection.'**
  String get atelierCrafted;

  /// No description provided for @atelierProtect.
  ///
  /// In fr, this message translates to:
  /// **'Protéger'**
  String get atelierProtect;

  /// No description provided for @atelierProtected.
  ///
  /// In fr, this message translates to:
  /// **'Protégée'**
  String get atelierProtected;

  /// No description provided for @atelierCraftHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fabriquer une carte précise'**
  String get atelierCraftHelpTitle;

  /// No description provided for @atelierCraftHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre une carte qui te manque dans l’Album, puis touche « Fabriquer ». Les cartes numérotées ne se fabriquent pas.'**
  String get atelierCraftHelp;

  /// No description provided for @atelierErrFragments.
  ///
  /// In fr, this message translates to:
  /// **'Pas assez de fragments.'**
  String get atelierErrFragments;

  /// No description provided for @atelierErrNotRecyclable.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte n’est pas recyclable (numérotée, protégée ou exposée).'**
  String get atelierErrNotRecyclable;

  /// No description provided for @atelierErrKeepOne.
  ///
  /// In fr, this message translates to:
  /// **'Il faut garder au moins un exemplaire de chaque carte.'**
  String get atelierErrKeepOne;

  /// No description provided for @atelierErrNotCraftable.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte ne se fabrique pas.'**
  String get atelierErrNotCraftable;

  /// No description provided for @atelierErrNotEligible.
  ///
  /// In fr, this message translates to:
  /// **'Cette rareté n’existe pas pour ce combattant.'**
  String get atelierErrNotEligible;

  /// No description provided for @defisTitle.
  ///
  /// In fr, this message translates to:
  /// **'Défis'**
  String get defisTitle;

  /// No description provided for @defisToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get defisToday;

  /// No description provided for @defisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get defisWeek;

  /// No description provided for @defisRenewIn.
  ///
  /// In fr, this message translates to:
  /// **'Renouvelés dans {time}'**
  String defisRenewIn(String time);

  /// No description provided for @defisClaim.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer'**
  String get defisClaim;

  /// No description provided for @defisClaimed.
  ///
  /// In fr, this message translates to:
  /// **'Récupéré'**
  String get defisClaimed;

  /// No description provided for @defisClaimedSnack.
  ///
  /// In fr, this message translates to:
  /// **'+{n} pièces'**
  String defisClaimedSnack(int n);

  /// No description provided for @defisError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les défis.'**
  String get defisError;

  /// No description provided for @defisErrAlready.
  ///
  /// In fr, this message translates to:
  /// **'Récompense déjà récupérée.'**
  String get defisErrAlready;

  /// No description provided for @defisErrNotDone.
  ///
  /// In fr, this message translates to:
  /// **'Ce défi n’est pas encore accompli.'**
  String get defisErrNotDone;

  /// No description provided for @durationDh.
  ///
  /// In fr, this message translates to:
  /// **'{d} j {h} h'**
  String durationDh(int d, int h);

  /// No description provided for @succesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get succesTitle;

  /// No description provided for @succesCount.
  ///
  /// In fr, this message translates to:
  /// **'{done} débloqués sur {total}'**
  String succesCount(int done, int total);

  /// No description provided for @succesError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les succès.'**
  String get succesError;

  /// No description provided for @succesErrNotDone.
  ///
  /// In fr, this message translates to:
  /// **'Ce succès n’est pas encore atteint.'**
  String get succesErrNotDone;

  /// No description provided for @navMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @menuAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get menuAccount;

  /// No description provided for @menuShop.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get menuShop;

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get shopTitle;

  /// No description provided for @shopBoosters.
  ///
  /// In fr, this message translates to:
  /// **'Boosters'**
  String get shopBoosters;

  /// No description provided for @shopFreeTest.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit (mode test)'**
  String get shopFreeTest;

  /// No description provided for @tacticLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tactique'**
  String get tacticLabel;

  /// No description provided for @tacticCardsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cartes Tactique'**
  String get tacticCardsTitle;

  /// No description provided for @tacticSecondSouffle.
  ///
  /// In fr, this message translates to:
  /// **'Second souffle'**
  String get tacticSecondSouffle;

  /// No description provided for @tacticCoinDuCoach.
  ///
  /// In fr, this message translates to:
  /// **'Coin du coach'**
  String get tacticCoinDuCoach;

  /// No description provided for @tacticFouleEnDelire.
  ///
  /// In fr, this message translates to:
  /// **'Foule en délire'**
  String get tacticFouleEnDelire;

  /// No description provided for @tacticMachoireAcier.
  ///
  /// In fr, this message translates to:
  /// **'Mâchoire d\'acier'**
  String get tacticMachoireAcier;

  /// No description provided for @tacticInstinctTueur.
  ///
  /// In fr, this message translates to:
  /// **'Instinct de tueur'**
  String get tacticInstinctTueur;

  /// No description provided for @tacticSortieDeCrise.
  ///
  /// In fr, this message translates to:
  /// **'Sortie de crise'**
  String get tacticSortieDeCrise;

  /// No description provided for @tacticPlanDeMatch.
  ///
  /// In fr, this message translates to:
  /// **'Plan de match'**
  String get tacticPlanDeMatch;

  /// No description provided for @tacticPressionTotale.
  ///
  /// In fr, this message translates to:
  /// **'Pression totale'**
  String get tacticPressionTotale;

  /// No description provided for @tacticEffectSecondSouffle.
  ///
  /// In fr, this message translates to:
  /// **'+{n} d’endurance'**
  String tacticEffectSecondSouffle(int n);

  /// No description provided for @tacticEffectCoinDuCoach.
  ///
  /// In fr, this message translates to:
  /// **'+{n} de santé'**
  String tacticEffectCoinDuCoach(int n);

  /// No description provided for @tacticEffectFouleEnDelire.
  ///
  /// In fr, this message translates to:
  /// **'+{n} de momentum'**
  String tacticEffectFouleEnDelire(int n);

  /// No description provided for @tacticEffectMachoireAcier.
  ///
  /// In fr, this message translates to:
  /// **'−{n} % de dégâts reçus pendant 2 échanges'**
  String tacticEffectMachoireAcier(int n);

  /// No description provided for @tacticEffectInstinctTueur.
  ///
  /// In fr, this message translates to:
  /// **'+{n} % de dégâts infligés pendant 2 échanges'**
  String tacticEffectInstinctTueur(int n);

  /// No description provided for @tacticEffectSortieDeCrise.
  ///
  /// In fr, this message translates to:
  /// **'Ta prochaine tentative pour te relever ou te dégager réussit, +{n} d’endurance'**
  String tacticEffectSortieDeCrise(int n);

  /// No description provided for @tacticEffectPlanDeMatch.
  ///
  /// In fr, this message translates to:
  /// **'+{n} % de réussite pendant 2 échanges'**
  String tacticEffectPlanDeMatch(int n);

  /// No description provided for @tacticEffectPressionTotale.
  ///
  /// In fr, this message translates to:
  /// **'L’adversaire perd {n} d’endurance'**
  String tacticEffectPressionTotale(int n);

  /// No description provided for @tacticRule.
  ///
  /// In fr, this message translates to:
  /// **'Bonus de combat : 2 cartes Tactique au plus par combat, une fois chacune. La carte reste dans ta collection.'**
  String get tacticRule;

  /// No description provided for @tacticByRarity.
  ///
  /// In fr, this message translates to:
  /// **'Effet selon la rareté'**
  String get tacticByRarity;

  /// No description provided for @tacticStarter.
  ///
  /// In fr, this message translates to:
  /// **'Cartes Tactique offertes'**
  String get tacticStarter;

  /// No description provided for @tacticStarterSub.
  ///
  /// In fr, this message translates to:
  /// **'3 bonus de combat pour bien commencer'**
  String get tacticStarterSub;

  /// No description provided for @tacticStarterAlready.
  ///
  /// In fr, this message translates to:
  /// **'Cartes Tactique déjà reçues'**
  String get tacticStarterAlready;

  /// No description provided for @tacticStarterUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Cartes Tactique pas encore disponibles : réessaie plus tard.'**
  String get tacticStarterUnavailable;

  /// No description provided for @boosterOddsTactic.
  ///
  /// In fr, this message translates to:
  /// **'Carte Tactique en plus ({n} par booster)'**
  String boosterOddsTactic(int n);

  /// No description provided for @combatQuick.
  ///
  /// In fr, this message translates to:
  /// **'Combat rapide'**
  String get combatQuick;

  /// No description provided for @combatQuickSub.
  ///
  /// In fr, this message translates to:
  /// **'Un combat contre l’IA, réglé à ta façon'**
  String get combatQuickSub;

  /// No description provided for @combatEvening.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get combatEvening;

  /// No description provided for @combatEveningSub.
  ///
  /// In fr, this message translates to:
  /// **'5 combats d’affilée'**
  String get combatEveningSub;

  /// No description provided for @combatRoad.
  ///
  /// In fr, this message translates to:
  /// **'Route vers la ceinture'**
  String get combatRoad;

  /// No description provided for @combatRoadSub.
  ///
  /// In fr, this message translates to:
  /// **'Gravis le classement jusqu’au combat pour le titre'**
  String get combatRoadSub;

  /// No description provided for @combatScenarios.
  ///
  /// In fr, this message translates to:
  /// **'Scénarios'**
  String get combatScenarios;

  /// No description provided for @combatScenariosSub.
  ///
  /// In fr, this message translates to:
  /// **'Rejoue les vraies rivalités, avec l’un ou l’autre combattant'**
  String get combatScenariosSub;

  /// No description provided for @combatSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get combatSoon;

  /// No description provided for @combatSetupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get combatSetupTitle;

  /// No description provided for @combatYourFighter.
  ///
  /// In fr, this message translates to:
  /// **'Ton combattant'**
  String get combatYourFighter;

  /// No description provided for @combatPickFighter.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un combattant'**
  String get combatPickFighter;

  /// No description provided for @combatNoFighter.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre des boosters pour obtenir des combattants.'**
  String get combatNoFighter;

  /// No description provided for @combatOpponent.
  ///
  /// In fr, this message translates to:
  /// **'Adversaire'**
  String get combatOpponent;

  /// No description provided for @combatReroll.
  ///
  /// In fr, this message translates to:
  /// **'Autre adversaire'**
  String get combatReroll;

  /// No description provided for @combatChooseOpponent.
  ///
  /// In fr, this message translates to:
  /// **'Choisir l’adversaire'**
  String get combatChooseOpponent;

  /// No description provided for @combatLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de l’IA'**
  String get combatLevel;

  /// No description provided for @combatLevelFacile.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get combatLevelFacile;

  /// No description provided for @combatLevelNormal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get combatLevelNormal;

  /// No description provided for @combatLevelDifficile.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get combatLevelDifficile;

  /// No description provided for @combatFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get combatFormat;

  /// No description provided for @combatFormatCourt.
  ///
  /// In fr, this message translates to:
  /// **'Court'**
  String get combatFormatCourt;

  /// No description provided for @combatFormatComplet.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get combatFormatComplet;

  /// No description provided for @combatFormatDetail.
  ///
  /// In fr, this message translates to:
  /// **'{rounds} rounds de {n} échanges'**
  String combatFormatDetail(int rounds, int n);

  /// No description provided for @combatWeight.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get combatWeight;

  /// No description provided for @combatSameClass.
  ///
  /// In fr, this message translates to:
  /// **'Même catégorie'**
  String get combatSameClass;

  /// No description provided for @combatOpenWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids libre'**
  String get combatOpenWeight;

  /// No description provided for @combatOpenWeightNote.
  ///
  /// In fr, this message translates to:
  /// **'Le plus léger encaisse plus et lutte moins bien.'**
  String get combatOpenWeightNote;

  /// No description provided for @combatControl.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get combatControl;

  /// No description provided for @combatControlCards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes'**
  String get combatControlCards;

  /// No description provided for @combatControlWheel.
  ///
  /// In fr, this message translates to:
  /// **'Roue'**
  String get combatControlWheel;

  /// No description provided for @combatTactics.
  ///
  /// In fr, this message translates to:
  /// **'Cartes Tactique (2 au plus)'**
  String get combatTactics;

  /// No description provided for @combatNoTactics.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte Tactique : tu en reçois une dans chaque booster.'**
  String get combatNoTactics;

  /// No description provided for @combatEnter.
  ///
  /// In fr, this message translates to:
  /// **'Entrer dans la cage'**
  String get combatEnter;

  /// No description provided for @combatRound.
  ///
  /// In fr, this message translates to:
  /// **'Round {r}'**
  String combatRound(int r);

  /// No description provided for @combatExchange.
  ///
  /// In fr, this message translates to:
  /// **'Échange {e}/{n}'**
  String combatExchange(int e, int n);

  /// No description provided for @combatHealth.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get combatHealth;

  /// No description provided for @combatStamina.
  ///
  /// In fr, this message translates to:
  /// **'Endurance'**
  String get combatStamina;

  /// No description provided for @combatMomentum.
  ///
  /// In fr, this message translates to:
  /// **'Momentum'**
  String get combatMomentum;

  /// No description provided for @combatYourMove.
  ///
  /// In fr, this message translates to:
  /// **'À toi de jouer'**
  String get combatYourMove;

  /// No description provided for @combatSignatureReady.
  ///
  /// In fr, this message translates to:
  /// **'Coup signature prêt !'**
  String get combatSignatureReady;

  /// No description provided for @combatStanceDebout.
  ///
  /// In fr, this message translates to:
  /// **'Debout'**
  String get combatStanceDebout;

  /// No description provided for @combatStanceClinch.
  ///
  /// In fr, this message translates to:
  /// **'Clinch'**
  String get combatStanceClinch;

  /// No description provided for @combatStanceDessus.
  ///
  /// In fr, this message translates to:
  /// **'Au sol, dessus'**
  String get combatStanceDessus;

  /// No description provided for @combatStanceDessous.
  ///
  /// In fr, this message translates to:
  /// **'Au sol, dessous'**
  String get combatStanceDessous;

  /// No description provided for @combatQuit.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get combatQuit;

  /// No description provided for @combatQuitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner ce combat ? Il compte comme une défaite.'**
  String get combatQuitConfirm;

  /// No description provided for @combatTimeUp.
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé : Garde'**
  String get combatTimeUp;

  /// No description provided for @actFrappeRapide.
  ///
  /// In fr, this message translates to:
  /// **'Frappe rapide'**
  String get actFrappeRapide;

  /// No description provided for @actFrappePuissante.
  ///
  /// In fr, this message translates to:
  /// **'Frappe puissante'**
  String get actFrappePuissante;

  /// No description provided for @actCoupDePied.
  ///
  /// In fr, this message translates to:
  /// **'Coup de pied'**
  String get actCoupDePied;

  /// No description provided for @actTakedown.
  ///
  /// In fr, this message translates to:
  /// **'Takedown'**
  String get actTakedown;

  /// No description provided for @actClinch.
  ///
  /// In fr, this message translates to:
  /// **'Clinch'**
  String get actClinch;

  /// No description provided for @actGarde.
  ///
  /// In fr, this message translates to:
  /// **'Garde'**
  String get actGarde;

  /// No description provided for @actEsquive.
  ///
  /// In fr, this message translates to:
  /// **'Esquive'**
  String get actEsquive;

  /// No description provided for @actGroundAndPound.
  ///
  /// In fr, this message translates to:
  /// **'Ground and pound'**
  String get actGroundAndPound;

  /// No description provided for @actSoumission.
  ///
  /// In fr, this message translates to:
  /// **'Soumission'**
  String get actSoumission;

  /// No description provided for @actSeRelever.
  ///
  /// In fr, this message translates to:
  /// **'Se relever'**
  String get actSeRelever;

  /// No description provided for @actSeDegager.
  ///
  /// In fr, this message translates to:
  /// **'Se dégager'**
  String get actSeDegager;

  /// No description provided for @actControle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle'**
  String get actControle;

  /// No description provided for @actSignature.
  ///
  /// In fr, this message translates to:
  /// **'Coup signature'**
  String get actSignature;

  /// No description provided for @evTouche.
  ///
  /// In fr, this message translates to:
  /// **'{a} place : {action} ({n})'**
  String evTouche(String a, String action, int n);

  /// No description provided for @evBloque.
  ///
  /// In fr, this message translates to:
  /// **'{b} bloque : {action}'**
  String evBloque(String b, String action);

  /// No description provided for @evBloqueTouche.
  ///
  /// In fr, this message translates to:
  /// **'{b} bloque mais encaisse {n}'**
  String evBloqueTouche(String b, int n);

  /// No description provided for @evRate.
  ///
  /// In fr, this message translates to:
  /// **'{a} manque : {action}'**
  String evRate(String a, String action);

  /// No description provided for @evEsquive.
  ///
  /// In fr, this message translates to:
  /// **'{a} esquive !'**
  String evEsquive(String a);

  /// No description provided for @evContre.
  ///
  /// In fr, this message translates to:
  /// **'Contre de {a} ! ({n})'**
  String evContre(String a, int n);

  /// No description provided for @evKnockdown.
  ///
  /// In fr, this message translates to:
  /// **'{a} envoie {b} au tapis !'**
  String evKnockdown(String a, String b);

  /// No description provided for @evTakedown.
  ///
  /// In fr, this message translates to:
  /// **'Takedown de {a} !'**
  String evTakedown(String a);

  /// No description provided for @evTakedownRate.
  ///
  /// In fr, this message translates to:
  /// **'{a} rate son takedown'**
  String evTakedownRate(String a);

  /// No description provided for @evClinch.
  ///
  /// In fr, this message translates to:
  /// **'{a} engage le clinch'**
  String evClinch(String a);

  /// No description provided for @evSepare.
  ///
  /// In fr, this message translates to:
  /// **'{a} se dégage'**
  String evSepare(String a);

  /// No description provided for @evReleve.
  ///
  /// In fr, this message translates to:
  /// **'{a} se relève'**
  String evReleve(String a);

  /// No description provided for @evControle.
  ///
  /// In fr, this message translates to:
  /// **'{a} contrôle au sol'**
  String evControle(String a);

  /// No description provided for @evSoumissionTentee.
  ///
  /// In fr, this message translates to:
  /// **'{a} tente une soumission !'**
  String evSoumissionTentee(String a);

  /// No description provided for @evSoumissionEchappee.
  ///
  /// In fr, this message translates to:
  /// **'{a} s’échappe !'**
  String evSoumissionEchappee(String a);

  /// No description provided for @evSoumissionReussie.
  ///
  /// In fr, this message translates to:
  /// **'{b} abandonne !'**
  String evSoumissionReussie(String b);

  /// No description provided for @evSignature.
  ///
  /// In fr, this message translates to:
  /// **'Coup signature de {a} !'**
  String evSignature(String a);

  /// No description provided for @evFatigue.
  ///
  /// In fr, this message translates to:
  /// **'{a} accuse la fatigue'**
  String evFatigue(String a);

  /// No description provided for @evTactique.
  ///
  /// In fr, this message translates to:
  /// **'{a} joue {tactic}'**
  String evTactique(String a, String tactic);

  /// No description provided for @evFinRound.
  ///
  /// In fr, this message translates to:
  /// **'Fin du round {n}'**
  String evFinRound(int n);

  /// No description provided for @evKo.
  ///
  /// In fr, this message translates to:
  /// **'KO ! {a} l’emporte'**
  String evKo(String a);

  /// No description provided for @evTko.
  ///
  /// In fr, this message translates to:
  /// **'Arrêt de l’arbitre ! {a} l’emporte'**
  String evTko(String a);

  /// No description provided for @evFinSoumission.
  ///
  /// In fr, this message translates to:
  /// **'Soumission ! {a} l’emporte'**
  String evFinSoumission(String a);

  /// No description provided for @evDecision.
  ///
  /// In fr, this message translates to:
  /// **'Décision des juges'**
  String get evDecision;

  /// No description provided for @methodKo.
  ///
  /// In fr, this message translates to:
  /// **'KO'**
  String get methodKo;

  /// No description provided for @methodTko.
  ///
  /// In fr, this message translates to:
  /// **'KO technique'**
  String get methodTko;

  /// No description provided for @methodSoumission.
  ///
  /// In fr, this message translates to:
  /// **'Soumission'**
  String get methodSoumission;

  /// No description provided for @methodDecisionUnanime.
  ///
  /// In fr, this message translates to:
  /// **'Décision unanime'**
  String get methodDecisionUnanime;

  /// No description provided for @methodDecisionPartagee.
  ///
  /// In fr, this message translates to:
  /// **'Décision partagée'**
  String get methodDecisionPartagee;

  /// No description provided for @methodDecisionMajoritaire.
  ///
  /// In fr, this message translates to:
  /// **'Décision majoritaire'**
  String get methodDecisionMajoritaire;

  /// No description provided for @methodNul.
  ///
  /// In fr, this message translates to:
  /// **'Match nul'**
  String get methodNul;

  /// No description provided for @combatWin.
  ///
  /// In fr, this message translates to:
  /// **'Victoire'**
  String get combatWin;

  /// No description provided for @combatLoss.
  ///
  /// In fr, this message translates to:
  /// **'Défaite'**
  String get combatLoss;

  /// No description provided for @combatDraw.
  ///
  /// In fr, this message translates to:
  /// **'Match nul'**
  String get combatDraw;

  /// No description provided for @combatResultLine.
  ///
  /// In fr, this message translates to:
  /// **'{method} · round {r}'**
  String combatResultLine(String method, int r);

  /// No description provided for @combatJudges.
  ///
  /// In fr, this message translates to:
  /// **'Cartes des juges'**
  String get combatJudges;

  /// No description provided for @combatJudge.
  ///
  /// In fr, this message translates to:
  /// **'Juge {n}'**
  String combatJudge(int n);

  /// No description provided for @combatRematch.
  ///
  /// In fr, this message translates to:
  /// **'Revanche'**
  String get combatRematch;

  /// No description provided for @combatBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get combatBack;

  /// No description provided for @subAttackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Soumission !'**
  String get subAttackTitle;

  /// No description provided for @subAttackHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche quand le curseur passe dans la zone verte (3 fois)'**
  String get subAttackHint;

  /// No description provided for @subDefendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dégage-toi !'**
  String get subDefendTitle;

  /// No description provided for @subDefendHint.
  ///
  /// In fr, this message translates to:
  /// **'Tape le plus vite possible'**
  String get subDefendHint;

  /// No description provided for @settingsTimer.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur de combat'**
  String get settingsTimer;

  /// No description provided for @settingsTimerSub.
  ///
  /// In fr, this message translates to:
  /// **'15 s pour choisir chaque action, sinon Garde'**
  String get settingsTimerSub;

  /// No description provided for @modeContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get modeContinue;

  /// No description provided for @modeUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get modeUpcoming;

  /// No description provided for @modeYou.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get modeYou;

  /// No description provided for @soireeCompose.
  ///
  /// In fr, this message translates to:
  /// **'Compose ta soirée avec 5 de tes combattants : chacun affronte un adversaire de sa catégorie.'**
  String get soireeCompose;

  /// No description provided for @soireeBout.
  ///
  /// In fr, this message translates to:
  /// **'Combat {n}'**
  String soireeBout(int n);

  /// No description provided for @soireeMainEvent.
  ///
  /// In fr, this message translates to:
  /// **'Main event · 5 rounds'**
  String get soireeMainEvent;

  /// No description provided for @soireeStart.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la soirée'**
  String get soireeStart;

  /// No description provided for @soireeNext.
  ///
  /// In fr, this message translates to:
  /// **'Combat suivant'**
  String get soireeNext;

  /// No description provided for @soireeSummary.
  ///
  /// In fr, this message translates to:
  /// **'{wins} victoire(s) sur 5'**
  String soireeSummary(int wins);

  /// No description provided for @soireeNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle soirée'**
  String get soireeNew;

  /// No description provided for @soireeQuit.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner la soirée'**
  String get soireeQuit;

  /// No description provided for @soireeQuitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner cette soirée ? Elle sera perdue.'**
  String get soireeQuitConfirm;

  /// No description provided for @soireeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Soirée · combat {n}/5'**
  String soireeLabel(int n);

  /// No description provided for @routeIntro.
  ///
  /// In fr, this message translates to:
  /// **'Bats les vrais classés de ta catégorie jusqu’au combat pour le titre. Une défaite et tu repars du début.'**
  String get routeIntro;

  /// No description provided for @routeNoRanking.
  ///
  /// In fr, this message translates to:
  /// **'Pas de classement officiel pour cette catégorie : choisis un autre combattant.'**
  String get routeNoRanking;

  /// No description provided for @routeRank.
  ///
  /// In fr, this message translates to:
  /// **'N°{n}'**
  String routeRank(int n);

  /// No description provided for @routeChampion.
  ///
  /// In fr, this message translates to:
  /// **'Champion'**
  String get routeChampion;

  /// No description provided for @routeTitleFight.
  ///
  /// In fr, this message translates to:
  /// **'Combat pour le titre'**
  String get routeTitleFight;

  /// No description provided for @routeTitleDefense.
  ///
  /// In fr, this message translates to:
  /// **'Défense du titre'**
  String get routeTitleDefense;

  /// No description provided for @routeStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la route'**
  String get routeStart;

  /// No description provided for @routeFight.
  ///
  /// In fr, this message translates to:
  /// **'Combattre'**
  String get routeFight;

  /// No description provided for @routeLost.
  ///
  /// In fr, this message translates to:
  /// **'Défaite : retour au début de la route.'**
  String get routeLost;

  /// No description provided for @routeWon.
  ///
  /// In fr, this message translates to:
  /// **'Champion ! Tu as conquis la ceinture.'**
  String get routeWon;

  /// No description provided for @routeNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle route'**
  String get routeNew;

  /// No description provided for @routeQuit.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner la route'**
  String get routeQuit;

  /// No description provided for @routeQuitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner cette route ? Ta progression sera perdue.'**
  String get routeQuitConfirm;

  /// No description provided for @routeSource.
  ///
  /// In fr, this message translates to:
  /// **'Classement officiel UFC du {date}'**
  String routeSource(String date);

  /// No description provided for @routeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Route · combat {n}/6'**
  String routeLabel(int n);

  /// No description provided for @rivalriesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les vraies rivalités de la base : rejoue-les avec l’un ou l’autre combattant.'**
  String get rivalriesIntro;

  /// No description provided for @rivalryFights.
  ///
  /// In fr, this message translates to:
  /// **'{n} combats'**
  String rivalryFights(int n);

  /// No description provided for @rivalryLocked.
  ///
  /// In fr, this message translates to:
  /// **'Il te faut une carte de l’un des deux combattants.'**
  String get rivalryLocked;

  /// No description provided for @rivalryPlayAs.
  ///
  /// In fr, this message translates to:
  /// **'Jouer avec {name}'**
  String rivalryPlayAs(String name);

  /// No description provided for @rivalryHistory.
  ///
  /// In fr, this message translates to:
  /// **'Les vrais combats'**
  String get rivalryHistory;

  /// No description provided for @rivalryDraw.
  ///
  /// In fr, this message translates to:
  /// **'Nul'**
  String get rivalryDraw;

  /// No description provided for @rivalryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune rivalité disponible.'**
  String get rivalryEmpty;

  /// No description provided for @rivalryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rivalité'**
  String get rivalryLabel;

  /// No description provided for @rivalryWonWith.
  ///
  /// In fr, this message translates to:
  /// **'Gagnée avec {name}'**
  String rivalryWonWith(String name);

  /// No description provided for @rewardCoins.
  ///
  /// In fr, this message translates to:
  /// **'+{n} pièces'**
  String rewardCoins(int n);

  /// No description provided for @rewardCapped.
  ///
  /// In fr, this message translates to:
  /// **'Plafond de pièces du jour atteint'**
  String get rewardCapped;

  /// No description provided for @rewardPending.
  ///
  /// In fr, this message translates to:
  /// **'Récompense en attente : envoi dès le retour du réseau'**
  String get rewardPending;

  /// No description provided for @rewardOffline.
  ///
  /// In fr, this message translates to:
  /// **'Combat hors ligne : sans récompense'**
  String get rewardOffline;

  /// No description provided for @rewardRefused.
  ///
  /// In fr, this message translates to:
  /// **'Combat non validé par le serveur'**
  String get rewardRefused;

  /// No description provided for @rewardChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du combat…'**
  String get rewardChecking;

  /// No description provided for @combatHistory.
  ///
  /// In fr, this message translates to:
  /// **'Derniers combats'**
  String get combatHistory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
