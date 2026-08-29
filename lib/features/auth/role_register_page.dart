import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session.dart';
import '../../core/supabase_providers.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';

/// Registration for one specific side of the marketplace.
///
/// The role is baked into the route, not chosen on this screen, so the account
/// is stamped at `signUp` time via user metadata. `handle_new_user()` copies
/// that metadata onto `profiles.account_type`, and `guard_account_type()` then
/// pins it — which is what actually enforces "one email, one role". Doing it
/// any later would leave a window where an account exists with no side.
class RoleRegisterPage extends ConsumerStatefulWidget {
  const RoleRegisterPage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<RoleRegisterPage> createState() => _RoleRegisterPageState();
}

class _RoleRegisterPageState extends ConsumerState<RoleRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isPurohit => widget.role == UserRole.purohit;
  String get _slug => _isPurohit ? 'purohit' : 'user';
  String get _other => _isPurohit ? 'a family' : 'a purohit';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter your email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'That does not look like an email address.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  /// Indian numbers are ten digits; anything longer is accepted so an overseas
  /// family can still be reached, but the shape is checked so a typo does not
  /// silently become the only way a purohit can call them back.
  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter a phone number.';
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
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

    final email = _email.text.trim();
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: _password.text,
        data: {
          'account_type': widget.role.wire,
          'phone': _phone.text.trim(),
          // `profiles.full_name` is NOT NULL and this form deliberately does
          // not ask for a name yet, so the local part stands in until the
          // profile screen replaces it.
          'full_name': email.split('@').first,
        },
      );

      // With `mailer_autoconfirm` on, Supabase does not error on a duplicate
      // address — it returns a decoy user with an empty identity list and no
      // session. That empty list is the only reliable tell.
      final identities = res.user?.identities;
      if (identities != null && identities.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'This email is already registered. If you signed up as '
              '$_other, use that login instead.';
        });
        return;
      }

      // Signup signs the account in immediately. The brief asks for
      // register -> login -> home, so hand the session back straight away.
      await ref.read(sessionProvider.notifier).signOut();

      if (!mounted) return;
      showAppSnack(
        context,
        'Account created. Sign in to continue.',
        tone: SnackTone.success,
      );
      context.go('/login/$_slug');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message.toLowerCase().contains('already')
            ? 'This email is already registered. If you signed up as $_other, '
                'use that login instead.'
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
        title: Text(_isPurohit ? 'Register as purohit' : 'Register'),
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
                      _isPurohit
                          ? 'Create your purohit account'
                          : 'Create your account',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      'An email can belong to one side of the app only. This '
                      'address will be registered as '
                      '${_isPurohit ? 'a purohit' : 'a family'}.',
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
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: Gap.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: 'At least 8 characters.',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: Gap.lg),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: _validatePhone,
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
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: Gap.md),
                    TextButton(
                      onPressed:
                          _busy ? null : () => context.go('/login/$_slug'),
                      child: const Text('I already have an account'),
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
