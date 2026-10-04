import 'package:flutter/widgets.dart';

/// Langues dans lesquelles le contenu traduit (distinctions…) est disponible.
const contentLanguages = {'fr', 'en'};

/// Langue du téléphone, ramenée à une langue de contenu disponible
/// (repli sur le français, langue de l'app).
String deviceLanguage(BuildContext context) {
  final code = View.of(context).platformDispatcher.locale.languageCode.toLowerCase();
  return contentLanguages.contains(code) ? code : 'fr';
}
