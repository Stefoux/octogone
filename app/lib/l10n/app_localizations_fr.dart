// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Octogone';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement…';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String toVerify(String fields) {
    return 'À vérifier : $fields';
  }

  @override
  String get missingConfig =>
      'Configuration Supabase manquante.\n\nCompile avec :\nflutter run --dart-define-from-file=config/app.json\n\n(fichier généré par scripts/supabase_setup.sh)';

  @override
  String get authTagline => 'Cartes de combattants entre amis';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get noAccount => 'Pas encore de compte ? Créer un compte';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get signupTitle => 'Créer un compte';

  @override
  String get pseudo => 'Pseudo';

  @override
  String get pseudoMin => '3 caractères minimum';

  @override
  String get pseudoChars => 'Lettres, chiffres, espace, « _ », « - » ou « . »';

  @override
  String get passwordMinLabel => 'Mot de passe (8 caractères min.)';

  @override
  String get passwordMin => '8 caractères minimum';

  @override
  String get confirmPassword => 'Confirme le mot de passe';

  @override
  String get passwordsDiffer => 'Les mots de passe diffèrent';

  @override
  String get createAccount => 'Créer mon compte';

  @override
  String get pseudoTaken => 'Ce pseudo est déjà pris.';

  @override
  String get errInvalidCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get errAlreadyRegistered => 'Un compte existe déjà avec cet email.';

  @override
  String get errPasswordShort =>
      'Mot de passe trop court (8 caractères minimum).';

  @override
  String get errEmailNotConfirmed => 'Email non confirmé.';

  @override
  String get errRateLimit =>
      'Trop de tentatives : réessaie dans quelques minutes.';

  @override
  String get errNoInternet => 'Pas de connexion internet.';

  @override
  String errUnexpected(String message) {
    return 'Erreur inattendue : $message';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navAlbum => 'Album';

  @override
  String get navFighters => 'Combattants';

  @override
  String get navFight => 'Combat';

  @override
  String get navProfile => 'Profil';

  @override
  String helloUser(String pseudo) {
    return 'Salut $pseudo !';
  }

  @override
  String get sync => 'Synchroniser';

  @override
  String get syncRunning => 'Synchronisation du contenu…';

  @override
  String get syncOffline => 'Hors ligne : contenu en cache';

  @override
  String syncUpToDate(String date) {
    return 'À jour ($date)';
  }

  @override
  String syncUpToDateReceived(String date, int count) {
    return 'À jour ($date) · $count éléments reçus';
  }

  @override
  String get syncWaiting => 'En attente de synchronisation';

  @override
  String get statFighters => 'combattants';

  @override
  String get statChampions => 'champions';

  @override
  String get statEditions => 'éditions';

  @override
  String get statMyCards => 'cartes';

  @override
  String get browseEditions => 'Mon album';

  @override
  String get browseEditionsSub => 'Classeurs par édition, complétion, filtres';

  @override
  String get allFighters => 'Tous les combattants';

  @override
  String get allFightersSub => 'Stats réelles et stats de jeu';

  @override
  String get dailyBooster => 'Booster quotidien';

  @override
  String get comingPhase3 => 'Arrive avec la phase 3';

  @override
  String get welcomePack => 'Pack de bienvenue';

  @override
  String get welcomePackSub => '15 cartes offertes, dont des rares';

  @override
  String get welcomePackOpen => 'Ouvrir';

  @override
  String welcomePackReceived(int count) {
    return 'Tu as reçu $count cartes !';
  }

  @override
  String get welcomePackAlready => 'Pack de bienvenue déjà reçu';

  @override
  String get effectsShowcase => 'Vitrine des effets';

  @override
  String get effectsShowcaseSub => 'Toutes les raretés en aperçu';

  @override
  String get fightersTitle => 'Combattants';

  @override
  String get searchFighters => 'Rechercher un nom ou un surnom';

  @override
  String get champions => 'Champions';

  @override
  String get downloadingFighters => 'Téléchargement des combattants…';

  @override
  String get downloadFailed =>
      'Impossible de télécharger le contenu. Vérifie ta connexion.';

  @override
  String get noFighters => 'Aucun combattant pour l’instant.';

  @override
  String get fighterNotFound => 'Combattant introuvable';

  @override
  String get unknownCountry => 'Pays inconnu';

  @override
  String get categoryToVerify => 'Catégorie à vérifier';

  @override
  String recordLabel(String record) {
    return 'Palmarès $record';
  }

  @override
  String get tagChampion => 'Champion';

  @override
  String get tagChampionF => 'Championne';

  @override
  String get tagFormerChampion => 'Ancien champion';

  @override
  String get tagFormerChampionF => 'Ancienne championne';

  @override
  String get tagRetired => 'Retraité';

  @override
  String get tagRetiredF => 'Retraitée';

  @override
  String get gameStats => 'Stats de jeu';

  @override
  String get gameStatsNote =>
      'Calculées à partir des statistiques réelles ci-dessous.';

  @override
  String get ufcStats => 'Statistiques UFC';

  @override
  String get sigStrikesPerMin => 'Frappes significatives / min';

  @override
  String get strikeAccuracy => 'Précision de frappe';

  @override
  String get strikesAbsorbed => 'Frappes encaissées / min';

  @override
  String get strikeDefense => 'Défense de frappe';

  @override
  String get takedownsPer15 => 'Takedowns / 15 min';

  @override
  String get takedownAccuracy => 'Précision des takedowns';

  @override
  String get takedownDefense => 'Défense de takedown';

  @override
  String get subsPer15 => 'Tentatives de soumission / 15 min';

  @override
  String get knockdownsPer15 => 'Knockdowns / 15 min';

  @override
  String get avgFightTime => 'Durée moyenne d’un combat';

  @override
  String minutesSeconds(int min, String sec) {
    return '$min min $sec';
  }

  @override
  String get proRecord => 'Palmarès professionnel';

  @override
  String get wins => 'Victoires';

  @override
  String get losses => 'Défaites';

  @override
  String get draws => 'Nuls';

  @override
  String get noContests => 'Sans décision';

  @override
  String methodBreakdown(String total, String ko, String sub, String dec) {
    return '$total  (KO $ko · Sou. $sub · Déc. $dec)';
  }

  @override
  String get ufcFights => 'Combats à l’UFC';

  @override
  String ufcFightsValue(String total, String wins, String losses) {
    return '$total ($wins V – $losses D)';
  }

  @override
  String get bonusFotn => 'Bonus « Combat de la soirée »';

  @override
  String get bonusPotn => 'Bonus « Performance de la soirée »';

  @override
  String get fiveRoundDecisions => 'Victoires par décision en 5 rounds';

  @override
  String get distinctions => 'Distinctions';

  @override
  String cardsCount(int count) {
    return 'Cartes ($count)';
  }

  @override
  String get albumTitle => 'Album';

  @override
  String get realEditions => 'Éditions réelles';

  @override
  String get originalEditions => 'Éditions originales';

  @override
  String get noEditions => 'Aucune édition en cache pour l’instant.';

  @override
  String editionCards(int count) {
    return '$count cartes';
  }

  @override
  String get originalCreation => 'création originale';

  @override
  String releaseDate(String date) {
    return 'Sortie : $date';
  }

  @override
  String seriesCount(int count) {
    return '$count séries';
  }

  @override
  String get parallels => 'Parallèles';

  @override
  String numberedSeries(int n) {
    return 'numérotée /$n';
  }

  @override
  String oddsLabel(String odds) {
    return 'cote $odds';
  }

  @override
  String get checklistSources => 'Sources de la checklist';

  @override
  String get seriesBase => 'Base';

  @override
  String get seriesAutographs => 'Autographes';

  @override
  String get seriesRelics => 'Reliques';

  @override
  String get seriesMoments => 'Moments Historiques';

  @override
  String get seriesCelebrations => 'Célébrations';

  @override
  String get seriesInsert => 'Insert';

  @override
  String completion(int owned, int total, int pct) {
    return '$owned/$total · $pct %';
  }

  @override
  String pageOf(int page, int total) {
    return 'Page $page/$total';
  }

  @override
  String get filterAllRarities => 'Toutes les raretés';

  @override
  String get filterAllCategories => 'Toutes les catégories';

  @override
  String get filterOwnedOnly => 'Possédées';

  @override
  String get filterSearchFighter => 'Combattant…';

  @override
  String get checklistView => 'Checklist';

  @override
  String get binderView => 'Classeur';

  @override
  String get notOwned => 'Non possédée';

  @override
  String ownedCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exemplaires',
      one: '1 exemplaire',
    );
    return '$_temp0';
  }

  @override
  String get emptySlot => 'Emplacement vide';

  @override
  String get cardFlipHint => 'Touche la carte pour la retourner';

  @override
  String get cardTiltHint => 'Incline ton téléphone';

  @override
  String get cardRecord => 'Palmarès';

  @override
  String get cardSignatureMove => 'Coup signature';

  @override
  String get cardSignatureLocked => 'Débloqué à partir d’Épique';

  @override
  String get cardHighlights => 'Faits marquants';

  @override
  String cardStatBonus(int n) {
    return 'Bonus de rareté +$n';
  }

  @override
  String cardSerial(int serial, int run) {
    return '$serial/$run';
  }

  @override
  String cardPrintRun(int run) {
    return 'Tirage /$run';
  }

  @override
  String get cardRookie => 'Recrue';

  @override
  String cardNumberInSeries(String number, int total) {
    return '$number/$total';
  }

  @override
  String get showcaseIntro =>
      'Chaque rareté a son effet. Touche une carte pour l’ouvrir en grand, puis incline ton téléphone.';

  @override
  String get showcasePreview => 'Aperçu';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLoading => 'Chargement du profil…';

  @override
  String get profileOffline => 'Profil indisponible hors ligne';

  @override
  String get administrator => 'Administrateur';

  @override
  String get myFriendCode => 'Mon code ami';

  @override
  String get copy => 'Copier';

  @override
  String get friendCodeCopied => 'Code ami copié';

  @override
  String get settings => 'Réglages';

  @override
  String get creditsAndSources => 'Crédits et sources';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get account => 'Compte';

  @override
  String get syncContent => 'Synchroniser le contenu';

  @override
  String get syncContentSub => 'Combattants, éditions, images';

  @override
  String get syncFailed => 'Dernière tentative échouée (hors ligne ?)';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String versionLabel(String version) {
    return 'Octogone · version $version';
  }

  @override
  String get creditsTitle => 'Crédits';

  @override
  String get creditsDisclaimer =>
      'Application personnelle, non commerciale et non officielle. Aucun logo officiel : les noms d’éditions apparaissent en texte et les cadres des cartes sont des créations originales.';

  @override
  String get dataSources => 'Sources des données';

  @override
  String get srcStats => 'Statistiques officielles des combattants';

  @override
  String get srcRecords => 'Palmarès détaillés, distinctions';

  @override
  String get srcNationality => 'Nationalité, date de naissance';

  @override
  String get srcChecklists => 'Checklists des éditions réelles';

  @override
  String get srcChecklistCheck => 'Recoupement des checklists';

  @override
  String get srcPhotos => 'Photos';

  @override
  String get srcPhotosWho => 'Wikimedia Commons (licences libres)';

  @override
  String get srcFont => 'Police Oswald (SIL Open Font License)';

  @override
  String photosCount(int count) {
    return 'Photos ($count)';
  }

  @override
  String get noPhotos => 'Aucune photo synchronisée.';

  @override
  String photoAuthor(String name) {
    return 'Auteur : $name';
  }

  @override
  String photoLicense(String name) {
    return 'Licence : $name';
  }

  @override
  String get fightComing => 'Le combat tactique arrive en phase 4.';

  @override
  String get rarityCommune => 'Commune';

  @override
  String get rarityPeuCommune => 'Peu commune';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpique => 'Épique';

  @override
  String get rarityLegendaire => 'Légendaire';

  @override
  String get rarityMythique => 'Mythique';

  @override
  String get effectAcier => 'Acier d’Octogone';

  @override
  String get effectNeon => 'Néon Main Event';

  @override
  String get effectFaceAFace => 'Face-à-Face';

  @override
  String get effectCicatrice => 'Cicatrice';

  @override
  String get effectOndeDeChoc => 'Onde de Choc';

  @override
  String get effectCleFatale => 'Clé Fatale';

  @override
  String get effectCeintureOr => 'Ceinture d’Or';

  @override
  String get effectHeritage => 'Héritage';

  @override
  String get effectMoment => 'Moment Historique';

  @override
  String get effectTrilogie => 'Trilogie';

  @override
  String get effectOctogoneNoir => 'Octogone Noir';

  @override
  String get effectMainLevee => 'Main Levée';

  @override
  String get wcPailleF => 'Poids paille (F)';

  @override
  String get wcMoucheF => 'Poids mouche (F)';

  @override
  String get wcCoqF => 'Poids coq (F)';

  @override
  String get wcPlumeF => 'Poids plume (F)';

  @override
  String get wcMouche => 'Poids mouche';

  @override
  String get wcCoq => 'Poids coq';

  @override
  String get wcPlume => 'Poids plume';

  @override
  String get wcLegers => 'Poids légers';

  @override
  String get wcMiMoyens => 'Poids mi-moyens';

  @override
  String get wcMoyens => 'Poids moyens';

  @override
  String get wcMiLourds => 'Poids mi-lourds';

  @override
  String get wcLourds => 'Poids lourds';

  @override
  String get statFrappe => 'Frappe';

  @override
  String get statPuissance => 'Puissance';

  @override
  String get statLutte => 'Lutte';

  @override
  String get statSoumission => 'Soumission';

  @override
  String get statDefense => 'Défense';

  @override
  String get statCardio => 'Cardio';

  @override
  String get statMenton => 'Menton';

  @override
  String get statFrappeShort => 'FRA';

  @override
  String get statPuissanceShort => 'PUI';

  @override
  String get statLutteShort => 'LUT';

  @override
  String get statSoumissionShort => 'SOU';

  @override
  String get statDefenseShort => 'DÉF';

  @override
  String get statCardioShort => 'CAR';

  @override
  String get statMentonShort => 'MEN';

  @override
  String get styleFrappeur => 'Frappeur';

  @override
  String get styleLutteur => 'Lutteur';

  @override
  String get styleGrappler => 'Grappler';

  @override
  String get styleComplet => 'Complet';
}
