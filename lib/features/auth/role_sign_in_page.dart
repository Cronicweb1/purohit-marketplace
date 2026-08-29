import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session.dart';
import '../../core/supabase_providers.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';

/// Login for one specific side of the marketplace.
///
/// Signing in has to succeed before `profiles` is readable, so the role check
/// happens *after* authentication and undoes itself with a `signOut()` on a
/// mismatch. That is deliberate: the alternative — an anonymous lookup of which
/// role an address belongs to — would turn this screen into an account
/// enumeration oracle.
class RoleSignInPage extends ConsumerStatefulWidget {
  const RoleSignInPage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<RoleSignInPage> createState() => _RoleSignInPageState();
}

class _RoleSignInPageState extends ConsumerState<RoleSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isPurohit => widget.role == UserRole.purohit;
  String get _slug => _isPurohit ? 'purohit' : 'user';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!supabaseReady) {
      setState(() => _error = 'Supabase is not configured in this build.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final res = await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final uid = res.user?.id;
      if (uid == null) throw const AuthException('Sign in failed.');

      final row = await supabase
          .from('profiles')
          .select('account_type')
          .eq('id', uid)
          .maybeSingle();

      // A row that predates the column, or is missing entirely, resolves to
      // `family` rather than blocking the login — onboarding will fix it.
      final actual = UserRole.parse(row?['account_type'] as String?);
      if (actual != widget.role) {
        await ref.read(sessionProvider.notifier).signOut();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = actual == UserRole.purohit
              ? 'This email is registered as a purohit. Use the purohit login.'
              : 'This email is registered as a family account. Use the user '
                  'login.';
        });
        return;
      }

      await ref.read(sessionProvider.notifier).refresh();
      if (!mounted) return;
      // The router owns the landing spot: once the session is `ready` it sends
      // both roles to the shell, which renders the right home for each.
      context.go('/jobs');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message.toLowerCase().contains('invalid login')
            ? 'Wrong email or password.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isPurohit ? AppColors.maroon : AppColors.saffron;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isPurohit ? 'Purohit login' : 'Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.xl, Gap.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isPurohit ? 'Welcome back, panditji' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      _isPurohit
                          ? 'Sign in to see requests near you.'
                          : 'Sign in to post a ritual and message purohits.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter your email.'
                          : null,
                    ),
                    const SizedBox(height: Gap.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Enter your password.' : null,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: Gap.lg),
                      Container(
                        padding: const EdgeInsets.all(Gap.md),
                        decoration: BoxDecoration(
                          color: AppColors.dangerTint,
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Gap.xl),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: Gap.md),
                    TextButton(
                      onPressed:
                          _busy ? null : () => context.go('/register/$_slug'),
                      child: const Text('Create an account instead'),
                    ),
                    // The landing funnel replaced `/sign-in`, which used to be
                    // the only screen linking to the console. Without this the
                    // admin route is reachable by deep link only.
                    Center(
                      child: TextButton(
                        onPressed:
                            _busy ? null : () => context.go('/admin-sign-in'),
                        child: const Text(
                          'Admin sign in',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
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
