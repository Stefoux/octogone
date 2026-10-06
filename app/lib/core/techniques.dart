/// Nom du coup signature (technique de finition tirée du palmarès Wikipedia,
/// voir data/scripts/fetch_fighters.py) dans la langue de l'app.
const _techniques = <String, (String, String)>{
  'punches': ('Rafale de poings', 'Flurry of punches'),
  'punch': ('Coup de poing', 'Punch'),
  'elbows': ('Coudes', 'Elbows'),
  'elbow': ('Coude', 'Elbow'),
  'spinning back elbow': ('Coude retourné', 'Spinning back elbow'),
  'knee': ('Genou', 'Knee'),
  'flying knee': ('Genou sauté', 'Flying knee'),
  'head kick': ('Coup de pied à la tête', 'Head kick'),
  'body kick': ('Coup de pied au corps', 'Body kick'),
  'leg kick': ('Low kick', 'Leg kick'),
  'front kick': ('Front kick', 'Front kick'),
  'spinning wheel kick': ('Coup de pied retourné circulaire', 'Spinning wheel kick'),
  'spinning back kick': ('Coup de pied retourné', 'Spinning back kick'),
  'spinning hook kick': ('Crochet du pied retourné', 'Spinning hook kick'),
  'soccer kick to the body': ('Coup de pied au corps au sol', 'Soccer kick to the body'),
  'rear-naked choke': ('Étranglement arrière', 'Rear-naked choke'),
  'guillotine choke': ('Guillotine', 'Guillotine choke'),
  'triangle choke': ('Triangle', 'Triangle choke'),
  'arm-triangle choke': ('Triangle de bras', 'Arm-triangle choke'),
  'brabo choke': ('Étranglement brabo', 'Brabo choke'),
  "d'arce choke": ("Étranglement d'Arce", "D'Arce choke"),
  'anaconda choke': ('Anaconda', 'Anaconda choke'),
  'north-south choke': ('Étranglement nord-sud', 'North-south choke'),
  'japanese necktie': ('Cravate japonaise', 'Japanese necktie'),
  'face crank': ('Clé de visage', 'Face crank'),
  'armbar': ('Clé de bras', 'Armbar'),
  'kimura': ('Kimura', 'Kimura'),
  'heel hook': ('Clé de talon', 'Heel hook'),
  'kneebar': ('Clé de genou', 'Kneebar'),
  'scarf hold armlock': ('Clé de bras en kesa', 'Scarf hold armlock'),
};

String? techniqueLabel(String? technique, String lang) {
  if (technique == null || technique.isEmpty) return null;
  final t = _techniques[technique.toLowerCase()];
  if (t != null) return lang == 'en' ? t.$2 : t.$1;
  // Technique rare non traduite : nom d'origine, avec majuscule.
  return technique[0].toUpperCase() + technique.substring(1);
}

const _methods = <String, (String, String)>{
  'decision': ('Décision', 'Decision'),
  'tko': ('KO technique', 'TKO'),
  'ko': ('KO', 'KO'),
  'submission': ('Soumission', 'Submission'),
  'technical submission': ('Soumission technique', 'Technical submission'),
  'draw': ('Match nul', 'Draw'),
  'nc': ('Sans décision', 'No contest'),
  'dq': ('Disqualification', 'Disqualification'),
};

const _methodDetails = <String, (String, String)>{
  'unanimous': ('unanime', 'unanimous'),
  'split': ('partagée', 'split'),
  'majority': ('majoritaire', 'majority'),
  'doctor stoppage': ('arrêt du médecin', 'doctor stoppage'),
  'retirement': ('abandon au coin', 'retirement'),
};

/// Méthode d'un vrai combat (« Submission (rear-naked choke) », données
/// Wikipedia) dans la langue de l'app ; ce qui n'est pas connu reste tel quel.
String fightMethodLabel(String raw, String lang) {
  final m = RegExp(r'^([^(]+?)\s*(?:\((.+)\))?$').firstMatch(raw.trim());
  if (m == null) return raw;
  final kind = _methods[m.group(1)!.toLowerCase()];
  final head = kind == null ? m.group(1)! : (lang == 'en' ? kind.$2 : kind.$1);
  final detail = m.group(2);
  if (detail == null) return head;
  final d = _methodDetails[detail.toLowerCase()];
  final tail = d != null ? (lang == 'en' ? d.$2 : d.$1) : techniqueLabel(detail, lang)!;
  return '$head ($tail)';
}
