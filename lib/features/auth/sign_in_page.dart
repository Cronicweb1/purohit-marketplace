import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_intent.dart';
import '../../core/supabase_providers.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';

/// Which door the user came through.
enum _Mode { signIn, registerPurohit }

/// Password first, emailed code second.
///
/// The project runs on Supabase's default email provider, which refuses
/// template edits on the free tier — so the magic-link mail carries a link and
/// never a {{ .Token }}. That made the code path unusable for everyone, and the
/// default provider also rate-limits hard (429 over_email_send_rate_limit after
/// a couple of sends an hour). Passwords need no mail at all, so they are the
/// primary route until custom SMTP is configured; the code path stays as a
/// fallback so nothing is lost when it starts working again.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _Mode _mode = _Mode.signIn;
  bool _useCode = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isRegister => _mode == _Mode.registerPurohit;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  /// Remembered across the round-trip so onboarding preselects the purohit
  /// role and lands them on /register-purohit instead of the jobs feed.
  void _rememberIntent() =>
      AuthIntent.remember(_isRegister ? UserRole.purohit : null);

  bool _begin() {
    if (!_formKey.currentState!.validate()) return false;
    if (!supabaseReady) {
      setState(() => _error = 'Supabase is not configured in this build.');
      return false;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    return true;
  }

  /// Sends the emailed code. Kept for when custom SMTP exists.
  Future<void> _sendCode() async {
    if (!_begin()) return;
    final email = _email.text.trim();
    try {
      await supabase.auth.signInWithOtp(email: email);
      _rememberIntent();
      if (!mounted) return;
      context.push('/verify?email=${Uri.encodeComponent(email)}');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithPassword() async {
    if (!_begin()) return;
    try {
      await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      _rememberIntent();
      if (!mounted) return;
      // The router redirect owns where we land: a brand new account goes to
      // /onboarding, an established one to /jobs.
      context.go('/');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAccount() async {
    if (!_begin()) return;
    try {
      // The signup trigger reads this metadata to stamp `account_type` on the
      // new profile row. Without it the account would be born as a family
      // account and `pandit_profiles_require_purohit` would then refuse the
      // listing this door exists to create.
      final res = await supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'account_type': UserRole.purohit.wire},
      );
      _rememberIntent();
      if (!mounted) return;
      if (res.session == null) {
        // Only happens if email confirmation gets switched back on.
        setState(() => _error =
            'Account created. Confirm your email address, then sign in.');
        return;
      }
      context.go('/');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  VoidCallback get _primaryAction {
    if (_useCode) return _sendCode;
    return _isRegister ? _createAccount : _signInWithPassword;
  }

  String get _primaryLabel {
    if (_useCode) return _isRegister ? 'Continue as a purohit' : 'Email me a code';
    return _isRegister ? 'Create purohit account' : 'Sign in';
  }

  String get _helperText {
    if (_useCode) {
      return _isRegister
          ? 'We will email you a 6-digit code, then walk you through your purohit profile.'
          : 'We will email you a 6-digit code.';
    }
    return _isRegister
        ? 'Pick a password of at least 8 characters. You can add your experience and certificate next.'
        : 'Use the password you set when you created your account.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Gap.lg),
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.marigold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.temple_hindu,
                      size: 34, color: AppColors.saffronDark),
                ),
                const SizedBox(height: Gap.xl),
                const Text(
                  'Purohit',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: Gap.sm),
                const Text(
                  'Find a verified purohit for your ceremony, or find work as one.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Gap.xl),
                _ModeTabs(mode: _mode, onChanged: _switchMode),
                const SizedBox(height: Gap.xl),
                if (_isRegister) ...[
                  Container(
                    padding: const EdgeInsets.all(Gap.lg),
                    decoration: BoxDecoration(
                      color: AppColors.saffronTint,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.self_improvement,
                                size: 18, color: AppColors.saffronDark),
                            SizedBox(width: Gap.sm),
                            Text(
                              'Joining as a purohit',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        SizedBox(height: Gap.sm),
                        Text(
                          'Create an account, then tell us about your experience '
                          'and add a Gurukul certificate or guru reference. An '
                          'admin reviews it before your listing goes live — you '
                          'can browse in the meantime.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                ],
                const Text(
                  'Email address',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Gap.sm),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return 'That does not look like an email address';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (_useCode) _primaryAction();
                  },
                ),
                if (!_useCode) ...[
                  const SizedBox(height: Gap.lg),
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Gap.sm),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [
                      _isRegister
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: _isRegister ? 'At least 8 characters' : 'Your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.isEmpty) return 'Enter your password';
                      if (_isRegister && value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _primaryAction(),
                  ),
                ],
                const SizedBox(height: Gap.md),
                Text(
                  _helperText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.4,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Gap.lg),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ],
                const SizedBox(height: Gap.xl),
                FilledButton(
                  onPressed: _busy ? null : _primaryAction,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_primaryLabel),
                ),
                const SizedBox(height: Gap.xs),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _useCode = !_useCode;
                              _password.clear();
                              _error = null;
                            }),
                    child: Text(
                      _useCode ? 'Use a password instead' : 'Email me a code instead',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: Gap.sm),
                OutlinedButton(
                  onPressed: () => context.go('/browse'),
                  child: const Text('Browse ceremonies without signing in'),
                ),
                const SizedBox(height: Gap.xl),
                const Divider(),
                const SizedBox(height: Gap.xs),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/admin-sign-in'),
                    child: const Text(
                      'Admin sign in',
                      style:
                          TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Upwork-style segmented switch: one control, two clearly labelled doors,
/// so nobody has to guess which button signs them up.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.saffronTint,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(child: _tab(_Mode.signIn, 'Sign in')),
          Expanded(child: _tab(_Mode.registerPurohit, 'Register as a purohit')),
        ],
      ),
    );
  }

  Widget _tab(_Mode value, String label) {
    final selected = value == mode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: Gap.sm),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.field - 3),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.saffronDark : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}
