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
  String get effectsShowcase => 'Galerie des effets';

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
  String get srcFont => 'Polices Oswald et Barlow (SIL Open Font License)';

  @override
  String get srcSounds => 'Effets sonores';

  @override
  String get srcSoundsWho => 'Synthétisés pour Octogone (aucun son externe)';

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

  @override
  String get boosterOpen => 'Ouvrir';

  @override
  String get boosterChooseCollections => 'Choisir d’autres collections';

  @override
  String get boosterCollectionsTitle => 'Collections';

  @override
  String boosterCards(int n) {
    return '$n cartes';
  }

  @override
  String get boosterStandard => 'Standard';

  @override
  String get boosterPremium => 'Premium';

  @override
  String get boosterEvent => 'Événement';

  @override
  String get boosterTestMode => 'Mode test : boosters illimités';

  @override
  String boosterFreeReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosters gratuits prêts',
      one: '1 booster gratuit prêt',
    );
    return '$_temp0';
  }

  @override
  String boosterNextFree(String time) {
    return 'Prochain booster gratuit dans $time';
  }

  @override
  String get boosterNoFree => 'Plus de booster gratuit pour l’instant';

  @override
  String boosterPayWithCoins(int price) {
    return 'Ouvrir ce booster pour $price pièces ?';
  }

  @override
  String boosterPrice(int price) {
    return '$price pièces';
  }

  @override
  String get boosterNotEnoughCoins => 'Pas assez de pièces.';

  @override
  String get boosterUnavailable => 'Ce booster n’est plus disponible.';

  @override
  String get boosterOdds => 'Probabilités';

  @override
  String boosterOddsPerPack(String n) {
    return '$n par booster';
  }

  @override
  String boosterOddsOneIn(int n) {
    return '1 sur $n boosters';
  }

  @override
  String boosterOddsPercent(int pct) {
    return '$pct % des boosters';
  }

  @override
  String boosterPity(int n) {
    return 'Au moins une Légendaire tous les $n boosters.';
  }

  @override
  String boosterPityLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Garantie dans $count boosters au plus tard.',
      one: 'Garantie au prochain booster au plus tard.',
    );
    return '$_temp0';
  }

  @override
  String get boosterNumberedNote =>
      'Les cartes numérotées (/50, 1/1…) n’existent qu’en nombre limité, pour tous les joueurs réunis.';

  @override
  String get boosterTearHint => 'Glisse le doigt le long du haut pour déchirer';

  @override
  String get boosterTapToReveal => 'Touche ou glisse pour révéler';

  @override
  String get boosterTapForNext => 'Glisse ou touche pour la suivante';

  @override
  String get boosterRevealAll => 'Tout révéler';

  @override
  String get boosterNew => 'NOUVELLE';

  @override
  String get boosterOpenAnother => 'Ouvrir un autre';

  @override
  String get boosterDone => 'Terminé';

  @override
  String get boosterOpening => 'Ouverture…';

  @override
  String coins(int n) {
    return '$n pièces';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get settingsSound => 'Sons';

  @override
  String get settingsSoundSub =>
      'Déchirure des boosters et révélation des cartes';

  @override
  String durationHm(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationM(int m) {
    return '$m min';
  }

  @override
  String get entryCta => 'ENTRER DANS L’OCTOGONE';

  @override
  String get homeFeatured => 'Collection en vedette';

  @override
  String get srcPackPhotos => 'Photos des sachets';

  @override
  String get srcPackPhotosWho =>
      'Photos officielles des combattants (usage privé)';

  @override
  String get vitrineTitle => 'Ma vitrine';

  @override
  String get vitrineSubtitle => 'Expose tes plus belles cartes.';

  @override
  String get vitrineEmpty =>
      'Ta vitrine est vide. Touche un emplacement pour exposer une carte.';

  @override
  String get vitrineReorderHint =>
      'Appui long puis glisse pour changer une carte de place.';

  @override
  String get vitrineHonor => 'Place d’honneur';

  @override
  String get vitrineEdit => 'Modifier';

  @override
  String get vitrineDone => 'Terminé';

  @override
  String get vitrinePickTitle => 'Choisir une carte';

  @override
  String get vitrinePickSearch => 'Rechercher un combattant';

  @override
  String get vitrinePickEmpty => 'Aucune carte à exposer.';

  @override
  String get vitrineAdd => 'Exposer dans ma vitrine';

  @override
  String get vitrineRemove => 'Retirer de ma vitrine';

  @override
  String get vitrineAdded => 'Carte exposée dans ta vitrine.';

  @override
  String get vitrineRemoved => 'Carte retirée de ta vitrine.';

  @override
  String get vitrineFull => 'Vitrine pleine : retire d’abord une carte.';

  @override
  String vitrineCount(int count, int total) {
    return '$count/$total';
  }

  @override
  String vitrineSaveError(String message) {
    return 'Impossible d’enregistrer la vitrine : $message';
  }

  @override
  String get atelierTitle => 'Atelier';

  @override
  String atelierFragments(int n) {
    return '$n fragments';
  }

  @override
  String get atelierRecycleAll => 'Recycler tous les doublons';

  @override
  String atelierRecycleAllSub(int count, int gain) {
    return '$count doublons · +$gain fragments';
  }

  @override
  String get atelierNoDuplicates => 'Aucun doublon à recycler pour l’instant.';

  @override
  String atelierRecycleConfirmTitle(int count) {
    return 'Recycler $count doublons ?';
  }

  @override
  String atelierRecycleConfirm(int gain) {
    return 'Tu gagnes $gain fragments. Tu gardes au moins un exemplaire de chaque carte.';
  }

  @override
  String atelierRecycled(int gain, int count) {
    return '+$gain fragments ($count cartes recyclées)';
  }

  @override
  String atelierRecycleOne(int gain) {
    return 'Recycler un doublon (+$gain)';
  }

  @override
  String get atelierRules =>
      'Les cartes numérotées, protégées ou exposées dans la vitrine ne sont jamais recyclées.';

  @override
  String atelierCraft(int cost) {
    return 'Fabriquer · $cost fragments';
  }

  @override
  String get atelierCraftTitle => 'Fabriquer cette carte ?';

  @override
  String atelierCraftConfirm(int cost) {
    return 'Elle coûte $cost fragments et rejoint ta collection.';
  }

  @override
  String get atelierCrafted => 'Carte fabriquée et ajoutée à ta collection.';

  @override
  String get atelierProtect => 'Protéger';

  @override
  String get atelierProtected => 'Protégée';

  @override
  String get atelierCraftHelpTitle => 'Fabriquer une carte précise';

  @override
  String get atelierCraftHelp =>
      'Ouvre une carte qui te manque dans l’Album, puis touche « Fabriquer ». Les cartes numérotées ne se fabriquent pas.';

  @override
  String get atelierErrFragments => 'Pas assez de fragments.';

  @override
  String get atelierErrNotRecyclable =>
      'Cette carte n’est pas recyclable (numérotée, protégée ou exposée).';

  @override
  String get atelierErrKeepOne =>
      'Il faut garder au moins un exemplaire de chaque carte.';

  @override
  String get atelierErrNotCraftable => 'Cette carte ne se fabrique pas.';

  @override
  String get atelierErrNotEligible =>
      'Cette rareté n’existe pas pour ce combattant.';

  @override
  String get defisTitle => 'Défis';

  @override
  String get defisToday => 'Aujourd’hui';

  @override
  String get defisWeek => 'Cette semaine';

  @override
  String defisRenewIn(String time) {
    return 'Renouvelés dans $time';
  }

  @override
  String get defisClaim => 'Récupérer';

  @override
  String get defisClaimed => 'Récupéré';

  @override
  String defisClaimedSnack(int n) {
    return '+$n pièces';
  }

  @override
  String get defisError => 'Impossible de charger les défis.';

  @override
  String get defisErrAlready => 'Récompense déjà récupérée.';

  @override
  String get defisErrNotDone => 'Ce défi n’est pas encore accompli.';

  @override
  String durationDh(int d, int h) {
    return '$d j $h h';
  }

  @override
  String get succesTitle => 'Succès';

  @override
  String succesCount(int done, int total) {
    return '$done débloqués sur $total';
  }

  @override
  String get succesError => 'Impossible de charger les succès.';

  @override
  String get succesErrNotDone => 'Ce succès n’est pas encore atteint.';

  @override
  String get navMenu => 'Menu';

  @override
  String get menuAccount => 'Compte';

  @override
  String get menuShop => 'Boutique';

  @override
  String get shopTitle => 'Boutique';

  @override
  String get shopBoosters => 'Boosters';

  @override
  String get shopFreeTest => 'Gratuit (mode test)';

  @override
  String get tacticLabel => 'Tactique';

  @override
  String get tacticCardsTitle => 'Cartes Tactique';

  @override
  String get tacticSecondSouffle => 'Second souffle';

  @override
  String get tacticCoinDuCoach => 'Coin du coach';

  @override
  String get tacticFouleEnDelire => 'Foule en délire';

  @override
  String get tacticMachoireAcier => 'Mâchoire d\'acier';

  @override
  String get tacticInstinctTueur => 'Instinct de tueur';

  @override
  String get tacticSortieDeCrise => 'Sortie de crise';

  @override
  String get tacticPlanDeMatch => 'Plan de match';

  @override
  String get tacticPressionTotale => 'Pression totale';

  @override
  String tacticEffectSecondSouffle(int n) {
    return '+$n d’endurance';
  }

  @override
  String tacticEffectCoinDuCoach(int n) {
    return '+$n de santé';
  }

  @override
  String tacticEffectFouleEnDelire(int n) {
    return '+$n de momentum';
  }

  @override
  String tacticEffectMachoireAcier(int n) {
    return '−$n % de dégâts reçus pendant 2 échanges';
  }

  @override
  String tacticEffectInstinctTueur(int n) {
    return '+$n % de dégâts infligés pendant 2 échanges';
  }

  @override
  String tacticEffectSortieDeCrise(int n) {
    return 'Ta prochaine tentative pour te relever ou te dégager réussit, +$n d’endurance';
  }

  @override
  String tacticEffectPlanDeMatch(int n) {
    return '+$n % de réussite pendant 2 échanges';
  }

  @override
  String tacticEffectPressionTotale(int n) {
    return 'L’adversaire perd $n d’endurance';
  }

  @override
  String get tacticRule =>
      'Bonus de combat : 2 cartes Tactique au plus par combat, une fois chacune. La carte reste dans ta collection.';

  @override
  String get tacticByRarity => 'Effet selon la rareté';

  @override
  String get tacticStarter => 'Cartes Tactique offertes';

  @override
  String get tacticStarterSub => '3 bonus de combat pour bien commencer';

  @override
  String get tacticStarterAlready => 'Cartes Tactique déjà reçues';

  @override
  String get tacticStarterUnavailable =>
      'Cartes Tactique pas encore disponibles : réessaie plus tard.';

  @override
  String boosterOddsTactic(int n) {
    return 'Carte Tactique en plus ($n par booster)';
  }

  @override
  String get combatQuick => 'Combat rapide';

  @override
  String get combatQuickSub => 'Un combat contre l’IA, réglé à ta façon';

  @override
  String get combatEvening => 'Soirée';

  @override
  String get combatEveningSub => '5 combats d’affilée';

  @override
  String get combatRoad => 'Route vers la ceinture';

  @override
  String get combatRoadSub =>
      'Gravis le classement jusqu’au combat pour le titre';

  @override
  String get combatScenarios => 'Scénarios';

  @override
  String get combatScenariosSub =>
      'Rejoue les vraies rivalités, avec l’un ou l’autre combattant';

  @override
  String get combatSoon => 'Bientôt';

  @override
  String get combatSetupTitle => 'Préparation';

  @override
  String get combatYourFighter => 'Ton combattant';

  @override
  String get combatPickFighter => 'Choisir un combattant';

  @override
  String get combatNoFighter =>
      'Ouvre des boosters pour obtenir des combattants.';

  @override
  String get combatOpponent => 'Adversaire';

  @override
  String get combatReroll => 'Autre adversaire';

  @override
  String get combatChooseOpponent => 'Choisir l’adversaire';

  @override
  String get combatLevel => 'Niveau de l’IA';

  @override
  String get combatLevelFacile => 'Facile';

  @override
  String get combatLevelNormal => 'Normal';

  @override
  String get combatLevelDifficile => 'Difficile';

  @override
  String get combatFormat => 'Format';

  @override
  String get combatFormatCourt => 'Court';

  @override
  String get combatFormatComplet => 'Complet';

  @override
  String combatFormatDetail(int rounds, int n) {
    return '$rounds rounds de $n échanges';
  }

  @override
  String get combatWeight => 'Catégorie';

  @override
  String get combatSameClass => 'Même catégorie';

  @override
  String get combatOpenWeight => 'Poids libre';

  @override
  String get combatOpenWeightNote =>
      'Le plus léger encaisse plus et lutte moins bien.';

  @override
  String get combatControl => 'Commandes';

  @override
  String get combatControlCards => 'Cartes';

  @override
  String get combatControlWheel => 'Roue';

  @override
  String get combatTactics => 'Cartes Tactique (2 au plus)';

  @override
  String get combatNoTactics =>
      'Aucune carte Tactique : tu en reçois une dans chaque booster.';

  @override
  String get combatEnter => 'Entrer dans la cage';

  @override
  String combatRound(int r) {
    return 'Round $r';
  }

  @override
  String combatExchange(int e, int n) {
    return 'Échange $e/$n';
  }

  @override
  String get combatHealth => 'Santé';

  @override
  String get combatStamina => 'Endurance';

  @override
  String get combatMomentum => 'Momentum';

  @override
  String get combatYourMove => 'À toi de jouer';

  @override
  String get combatSignatureReady => 'Coup signature prêt !';

  @override
  String get combatStanceDebout => 'Debout';

  @override
  String get combatStanceClinch => 'Clinch';

  @override
  String get combatStanceDessus => 'Au sol, dessus';

  @override
  String get combatStanceDessous => 'Au sol, dessous';

  @override
  String get combatQuit => 'Abandonner';

  @override
  String get combatQuitConfirm =>
      'Abandonner ce combat ? Il compte comme une défaite.';

  @override
  String get combatTimeUp => 'Temps écoulé : Garde';

  @override
  String get actFrappeRapide => 'Frappe rapide';

  @override
  String get actFrappePuissante => 'Frappe puissante';

  @override
  String get actCoupDePied => 'Coup de pied';

  @override
  String get actTakedown => 'Takedown';

  @override
  String get actClinch => 'Clinch';

  @override
  String get actGarde => 'Garde';

  @override
  String get actEsquive => 'Esquive';

  @override
  String get actGroundAndPound => 'Ground and pound';

  @override
  String get actSoumission => 'Soumission';

  @override
  String get actSeRelever => 'Se relever';

  @override
  String get actSeDegager => 'Se dégager';

  @override
  String get actControle => 'Contrôle';

  @override
  String get actSignature => 'Coup signature';

  @override
  String evTouche(String a, String action, int n) {
    return '$a place : $action ($n)';
  }

  @override
  String evBloque(String b, String action) {
    return '$b bloque : $action';
  }

  @override
  String evBloqueTouche(String b, int n) {
    return '$b bloque mais encaisse $n';
  }

  @override
  String evRate(String a, String action) {
    return '$a manque : $action';
  }

  @override
  String evEsquive(String a) {
    return '$a esquive !';
  }

  @override
  String evContre(String a, int n) {
    return 'Contre de $a ! ($n)';
  }

  @override
  String evKnockdown(String a, String b) {
    return '$a envoie $b au tapis !';
  }

  @override
  String evTakedown(String a) {
    return 'Takedown de $a !';
  }

  @override
  String evTakedownRate(String a) {
    return '$a rate son takedown';
  }

  @override
  String evClinch(String a) {
    return '$a engage le clinch';
  }

  @override
  String evSepare(String a) {
    return '$a se dégage';
  }

  @override
  String evReleve(String a) {
    return '$a se relève';
  }

  @override
  String evControle(String a) {
    return '$a contrôle au sol';
  }

  @override
  String evSoumissionTentee(String a) {
    return '$a tente une soumission !';
  }

  @override
  String evSoumissionEchappee(String a) {
    return '$a s’échappe !';
  }

  @override
  String evSoumissionReussie(String b) {
    return '$b abandonne !';
  }

  @override
  String evSignature(String a) {
    return 'Coup signature de $a !';
  }

  @override
  String evFatigue(String a) {
    return '$a accuse la fatigue';
  }

  @override
  String evTactique(String a, String tactic) {
    return '$a joue $tactic';
  }

  @override
  String evFinRound(int n) {
    return 'Fin du round $n';
  }

  @override
  String evKo(String a) {
    return 'KO ! $a l’emporte';
  }

  @override
  String evTko(String a) {
    return 'Arrêt de l’arbitre ! $a l’emporte';
  }

  @override
  String evFinSoumission(String a) {
    return 'Soumission ! $a l’emporte';
  }

  @override
  String get evDecision => 'Décision des juges';

  @override
  String get methodKo => 'KO';

  @override
  String get methodTko => 'KO technique';

  @override
  String get methodSoumission => 'Soumission';

  @override
  String get methodDecisionUnanime => 'Décision unanime';

  @override
  String get methodDecisionPartagee => 'Décision partagée';

  @override
  String get methodDecisionMajoritaire => 'Décision majoritaire';

  @override
  String get methodNul => 'Match nul';

  @override
  String get combatWin => 'Victoire';

  @override
  String get combatLoss => 'Défaite';

  @override
  String get combatDraw => 'Match nul';

  @override
  String combatResultLine(String method, int r) {
    return '$method · round $r';
  }

  @override
  String get combatJudges => 'Cartes des juges';

  @override
  String combatJudge(int n) {
    return 'Juge $n';
  }

  @override
  String get combatRematch => 'Revanche';

  @override
  String get combatBack => 'Retour';

  @override
  String get subAttackTitle => 'Soumission !';

  @override
  String get subAttackHint =>
      'Touche quand le curseur passe dans la zone verte (3 fois)';

  @override
  String get subDefendTitle => 'Dégage-toi !';

  @override
  String get subDefendHint => 'Tape le plus vite possible';

  @override
  String get settingsTimer => 'Minuteur de combat';

  @override
  String get settingsTimerSub => '15 s pour choisir chaque action, sinon Garde';

  @override
  String get modeContinue => 'Continuer';

  @override
  String get modeUpcoming => 'À venir';

  @override
  String get modeYou => 'Toi';

  @override
  String get soireeCompose =>
      'Compose ta soirée avec 5 de tes combattants : chacun affronte un adversaire de sa catégorie.';

  @override
  String soireeBout(int n) {
    return 'Combat $n';
  }

  @override
  String get soireeMainEvent => 'Main event · 5 rounds';

  @override
  String get soireeStart => 'Lancer la soirée';

  @override
  String get soireeNext => 'Combat suivant';

  @override
  String soireeSummary(int wins) {
    return '$wins victoire(s) sur 5';
  }

  @override
  String get soireeNew => 'Nouvelle soirée';

  @override
  String get soireeQuit => 'Abandonner la soirée';

  @override
  String get soireeQuitConfirm => 'Abandonner cette soirée ? Elle sera perdue.';

  @override
  String soireeLabel(int n) {
    return 'Soirée · combat $n/5';
  }

  @override
  String get routeIntro =>
      'Bats les vrais classés de ta catégorie jusqu’au combat pour le titre. Une défaite et tu repars du début.';

  @override
  String get routeNoRanking =>
      'Pas de classement officiel pour cette catégorie : choisis un autre combattant.';

  @override
  String routeRank(int n) {
    return 'N°$n';
  }

  @override
  String get routeChampion => 'Champion';

  @override
  String get routeTitleFight => 'Combat pour le titre';

  @override
  String get routeTitleDefense => 'Défense du titre';

  @override
  String get routeStart => 'Commencer la route';

  @override
  String get routeFight => 'Combattre';

  @override
  String get routeLost => 'Défaite : retour au début de la route.';

  @override
  String get routeWon => 'Champion ! Tu as conquis la ceinture.';

  @override
  String get routeNew => 'Nouvelle route';

  @override
  String get routeQuit => 'Abandonner la route';

  @override
  String get routeQuitConfirm =>
      'Abandonner cette route ? Ta progression sera perdue.';

  @override
  String routeSource(String date) {
    return 'Classement officiel UFC du $date';
  }

  @override
  String routeLabel(int n) {
    return 'Route · combat $n/6';
  }

  @override
  String get rivalriesIntro =>
      'Les vraies rivalités de la base : rejoue-les avec l’un ou l’autre combattant.';

  @override
  String rivalryFights(int n) {
    return '$n combats';
  }

  @override
  String get rivalryLocked =>
      'Il te faut une carte de l’un des deux combattants.';

  @override
  String rivalryPlayAs(String name) {
    return 'Jouer avec $name';
  }

  @override
  String get rivalryHistory => 'Les vrais combats';

  @override
  String get rivalryDraw => 'Nul';

  @override
  String get rivalryEmpty => 'Aucune rivalité disponible.';

  @override
  String get rivalryLabel => 'Rivalité';

  @override
  String rivalryWonWith(String name) {
    return 'Gagnée avec $name';
  }

  @override
  String rewardCoins(int n) {
    return '+$n pièces';
  }

  @override
  String get rewardCapped => 'Plafond de pièces du jour atteint';

  @override
  String get rewardPending =>
      'Récompense en attente : envoi dès le retour du réseau';

  @override
  String get rewardOffline => 'Combat hors ligne : sans récompense';

  @override
  String get rewardRefused => 'Combat non validé par le serveur';

  @override
  String get rewardChecking => 'Vérification du combat…';

  @override
  String get combatHistory => 'Derniers combats';
}
