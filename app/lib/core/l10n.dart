import 'package:flutter/widgets.dart';
import 'package:game_core/game_core.dart';

import '../l10n/app_localizations.dart';
import 'countries.dart';

export '../l10n/app_localizations.dart';

/// Langues de l'app : français (par défaut) et anglais, selon le téléphone.
const appLocales = [Locale('fr'), Locale('en')];

/// Choisit la langue de l'app à partir de celles du téléphone (repli : français).
Locale resolveAppLocale(List<Locale>? deviceLocales) {
  for (final l in deviceLocales ?? const <Locale>[]) {
    if (l.languageCode == 'fr') return const Locale('fr');
    if (l.languageCode == 'en') return const Locale('en');
  }
  return const Locale('fr');
}

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 'fr' ou 'en' : langue effective de l'app (pour le contenu traduit des données).
  String get lang => Localizations.localeOf(this).languageCode == 'en' ? 'en' : 'fr';
}

String weightClassLabel(AppLocalizations l, WeightClass? w) => switch (w) {
      WeightClass.pailleF => l.wcPailleF,
      WeightClass.moucheF => l.wcMoucheF,
      WeightClass.coqF => l.wcCoqF,
      WeightClass.plumeF => l.wcPlumeF,
      WeightClass.mouche => l.wcMouche,
      WeightClass.coq => l.wcCoq,
      WeightClass.plume => l.wcPlume,
      WeightClass.legers => l.wcLegers,
      WeightClass.miMoyens => l.wcMiMoyens,
      WeightClass.moyens => l.wcMoyens,
      WeightClass.miLourds => l.wcMiLourds,
      WeightClass.lourds => l.wcLourds,
      null => l.categoryToVerify,
    };

/// Libellé court pour les puces de filtre (« légers », « Lightweight »…).
String weightClassShort(AppLocalizations l, WeightClass w) {
  final full = weightClassLabel(l, w);
  return full.replaceFirst('Poids ', '').replaceFirst("Women's ", 'W. ');
}

String statLabel(AppLocalizations l, StatKind k) => switch (k) {
      StatKind.frappe => l.statFrappe,
      StatKind.puissance => l.statPuissance,
      StatKind.lutte => l.statLutte,
      StatKind.soumission => l.statSoumission,
      StatKind.defense => l.statDefense,
      StatKind.cardio => l.statCardio,
      StatKind.menton => l.statMenton,
    };

String statShort(AppLocalizations l, StatKind k) => switch (k) {
      StatKind.frappe => l.statFrappeShort,
      StatKind.puissance => l.statPuissanceShort,
      StatKind.lutte => l.statLutteShort,
      StatKind.soumission => l.statSoumissionShort,
      StatKind.defense => l.statDefenseShort,
      StatKind.cardio => l.statCardioShort,
      StatKind.menton => l.statMentonShort,
    };

String styleLabel(AppLocalizations l, FighterStyle s) => switch (s) {
      FighterStyle.frappeur => l.styleFrappeur,
      FighterStyle.lutteur => l.styleLutteur,
      FighterStyle.grappler => l.styleGrappler,
      FighterStyle.complet => l.styleComplet,
    };

String rarityLabel(AppLocalizations l, String rarete) => switch (rarete) {
      'commune' => l.rarityCommune,
      'peu_commune' => l.rarityPeuCommune,
      'rare' => l.rarityRare,
      'epique' => l.rarityEpique,
      'legendaire' => l.rarityLegendaire,
      'mythique' => l.rarityMythique,
      _ => rarete,
    };

/// Nom affiché d'une variante : raretés originales traduites, parallèles réels
/// (noms propres : « Gold Refractor »…) laissés tels quels.
String variantLabel(AppLocalizations l, String effet, String fallback) => switch (effet) {
      'acier' => l.effectAcier,
      'neon' => l.effectNeon,
      'face_a_face' => l.effectFaceAFace,
      'cicatrice' => l.effectCicatrice,
      'onde_de_choc' => l.effectOndeDeChoc,
      'cle_fatale' => l.effectCleFatale,
      'ceinture_or' => l.effectCeintureOr,
      'heritage' => l.effectHeritage,
      'moment' => l.effectMoment,
      'trilogie' => l.effectTrilogie,
      'octogone_noir' => l.effectOctogoneNoir,
      'main_levee' => l.effectMainLevee,
      _ => fallback,
    };

String seriesTypeLabel(AppLocalizations l, String type) => switch (type) {
      'base' => l.seriesBase,
      'autographe' => l.seriesAutographs,
      'relique' => l.seriesRelics,
      'moment' => l.seriesMoments,
      'celebration' => l.seriesCelebrations,
      _ => l.seriesInsert,
    };

String countryLabel(BuildContext context, String? iso) {
  if (iso == null) return context.l10n.unknownCountry;
  return context.lang == 'en' ? (countryNamesEn[iso] ?? iso) : (countryNamesFr[iso] ?? iso);
}
