import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/octagon_emblem.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).signIn(_email.text, _password.text);
    } catch (e) {
      setState(() => _error = authErrorMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    const _Brand(),
                    const SizedBox(height: 40),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline)),
                      validator: (v) => (v == null || !v.contains('@')) ? l.invalidEmail : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: l.password, prefixIcon: const Icon(Icons.lock_outline)),
                      validator: (v) => (v == null || v.isEmpty) ? l.passwordRequired : null,
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
                          : Text(l.signIn),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/inscription'),
                      child: Text(l.noAccount),
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

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OctagonEmblem(size: 92, child: Icon(Icons.sports_mma, size: 34, color: AppColors.gold)),
        const SizedBox(height: 18),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(
            colors: [AppColors.goldDeep, Color(0xFFF7E2AE), AppColors.gold],
          ).createShader(r),
          child: const Text('OCTOGONE',
              style: TextStyle(fontFamily: kDisplayFont, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 6)),
        ),
        const SizedBox(height: 4),
        Text(context.l10n.authTagline,
            style: const TextStyle(color: AppColors.textMuted, letterSpacing: 0.4, fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
