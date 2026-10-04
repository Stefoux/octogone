import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _pseudo = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_pseudo, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider);
    try {
      if (!await auth.pseudoAvailable(_pseudo.text.trim())) {
        setState(() => _error = 'Ce pseudo est déjà pris.');
        return;
      }
      await auth.signUp(pseudo: _pseudo.text, email: _email.text, password: _password.text);
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/connexion')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('signup-pseudo'),
                      controller: _pseudo,
                      maxLength: 20,
                      decoration: const InputDecoration(labelText: 'Pseudo', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.length < 3) return '3 caractères minimum';
                        if (!RegExp(r'^[\p{L}\p{N}_ .-]+$', unicode: true).hasMatch(t)) {
                          return 'Lettres, chiffres, espace, « _ », « - » ou « . »';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      key: const Key('signup-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => (v == null || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim()))
                          ? 'Email invalide'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('signup-password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Mot de passe (8 caractères min.)', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => (v == null || v.length < 8) ? '8 caractères minimum' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('signup-confirm'),
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Confirme le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => v != _password.text ? 'Les mots de passe diffèrent' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.crimson)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Créer mon compte'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
