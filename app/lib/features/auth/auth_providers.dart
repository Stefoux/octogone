import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n.dart';
import '../../data/repositories/content_providers.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

/// Session courante (persistée par supabase_flutter : l'app s'ouvre hors ligne).
final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentSession;
});

class Profile {
  const Profile({
    required this.id,
    required this.pseudo,
    required this.friendCode,
    required this.isAdmin,
    required this.adminMode,
    required this.welcomePackReceived,
    this.tacticStarterReceived = true,
  });
  final String id;
  final String pseudo;
  final String friendCode;
  final bool isAdmin;
  final bool adminMode;
  final bool welcomePackReceived;

  /// Cartes Tactique de départ déjà reçues.
  final bool tacticStarterReceived;
}

final profileProvider = FutureProvider<Profile?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  final client = ref.watch(supabaseProvider);
  final uid = session.user.id;
  final p = await client.from('profiles').select('id, pseudo, friend_code, admin_mode, pack_bienvenue_le, tactiques_depart_le').eq('id', uid).single();
  final role = await client.from('user_roles').select('role').eq('user_id', uid).maybeSingle();
  return Profile(
    id: uid,
    pseudo: p['pseudo'] as String,
    friendCode: p['friend_code'] as String,
    adminMode: p['admin_mode'] == true,
    isAdmin: role?['role'] == 'admin',
    welcomePackReceived: p['pack_bienvenue_le'] != null,
    tacticStarterReceived: p['tactiques_depart_le'] != null,
  );
});

/// Traduit les erreurs d'authentification Supabase dans la langue de l'app.
String authErrorMessage(AppLocalizations l, Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return l.errInvalidCredentials;
    if (m.contains('already registered') || m.contains('already been registered')) {
      return l.errAlreadyRegistered;
    }
    if (m.contains('password should be at least')) return l.errPasswordShort;
    if (m.contains('email not confirmed')) return l.errEmailNotConfirmed;
    if (m.contains('rate limit')) return l.errRateLimit;
    if (m.contains('invalid') && m.contains('email')) return l.invalidEmail;
    return e.message;
  }
  if ('$e'.contains('SocketException') || '$e'.contains('Failed host lookup')) {
    return l.errNoInternet;
  }
  return l.errUnexpected('$e');
}

class AuthController {
  AuthController(this.ref);
  final Ref ref;

  GoTrueClient get _auth => ref.read(supabaseProvider).auth;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email.trim(), password: password);

  Future<bool> pseudoAvailable(String pseudo) async {
    final r = await ref.read(supabaseProvider).rpc<bool>('pseudo_disponible', params: {'p': pseudo});
    return r;
  }

  Future<void> signUp({required String pseudo, required String email, required String password}) =>
      _auth.signUp(email: email.trim(), password: password, data: {'pseudo': pseudo.trim()});

  Future<void> signOut() => _auth.signOut();
}

final authControllerProvider = Provider<AuthController>(AuthController.new);
