/// Configuration injectée à la compilation :
///   flutter run --dart-define-from-file=config/app.json
///
/// config/app.json est généré par scripts/supabase_setup.sh à partir du .env
/// (jamais versionné). La clé « publishable » (ou « anon ») est faite pour être
/// embarquée dans une app : la sécurité repose sur les policies RLS.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  /// URL publique d'une image du bucket « cartes ».
  static String publicImageUrl(String storagePath) =>
      '$supabaseUrl/storage/v1/object/public/cartes/$storagePath';
}
