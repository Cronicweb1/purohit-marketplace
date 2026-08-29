import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session.dart';
import '../../core/supabase_providers.dart';
import '../../theme/app_theme.dart';

/// Admin login.
///
/// Password-first, unlike the public sign-in. Admin accounts are provisioned
/// directly in Supabase with a password already set, so the console stays
/// reachable even when transactional email is down or unconfigured — which is
/// exactly the situation an admin is most likely to be called in to fix.
///
/// The emailed code is kept as a second route for admins who would rather not
/// hold a password. Either way the destination is the same: this screen refuses
/// to continue if the session does not carry the admin role, so an admin never
/// has to hunt for the console inside the family/purohit UI.
class AdminSignInPage extends ConsumerStatefulWidget {
  const AdminSignInPage({super.key});

  @override
  ConsumerState<AdminSignInPage> createState() => _AdminSignInPageState();
}

class _AdminSignInPageState extends ConsumerState<AdminSignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  bool _useCode = false;
  bool _codeSent = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  bool _emailLooksValid() =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  /// Shared tail of both routes: a session exists, now prove it is privileged.
  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).refresh();
    if (!mounted) return;

    if (!ref.read(sessionProvider).isAdmin) {
      // Signed in, but not privileged. Drop the session rather than silently
      // leaving them logged in on a screen that promised an admin console.
      await ref.read(sessionProvider.notifier).signOut();
      if (!mounted) return;
      setState(() => _error =
          'That account is not an administrator. Ask the project owner to '
          'set app_metadata.role = "admin" in Supabase.');
      return;
    }
    if (!mounted) return;
    context.go('/admin');
  }

  Future<void> _signInWithPassword() async {
    if (!_emailLooksValid()) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    if (!supabaseReady) {
      setState(() => _error = 'Backend not configured.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await _finish();
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

  Future<void> _send() async {
    if (!_emailLooksValid()) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (!supabaseReady) {
      setState(() => _error = 'Backend not configured.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // shouldCreateUser: false — an admin account is provisioned in Supabase,
      // never bootstrapped by typing a fresh address into this box.
      await supabase.auth.signInWithOtp(
          email: _email.text.trim(), shouldCreateUser: false);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final token = _code.text.trim();
    if (token.length < 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supabase.auth.verifyOTP(
        type: OtpType.email,
        email: _email.text.trim(),
        token: token,
      );
      await _finish();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'That code did not work. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  VoidCallback? get _primaryAction {
    if (_busy) return null;
    if (!_useCode) return _signInWithPassword;
    return _codeSent ? _verify : _send;
  }

  String get _primaryLabel {
    if (!_useCode) return 'Sign in to console';
    return _codeSent ? 'Verify and open console' : 'Send code';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin sign in'),
        // Admins arrive here with `go`, not `push`, so there is no back stack
        // and Flutter renders no back arrow. Without an explicit control this
        // screen is a dead end: no swipe-back, and the only way out is the
        // link at the very bottom of a scrolling form.
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.admin_panel_settings_outlined,
                  size: 36, color: AppColors.saffronDark),
              const SizedBox(height: Gap.lg),
              const Text(
                'Verification console',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Gap.sm),
              const Text(
                'For the team that reviews purohit applications. The admin role '
                'is granted in Supabase and cannot be requested from the app.',
                style: TextStyle(
                    fontSize: 13.5, height: 1.5, color: AppColors.inkMuted),
              ),
              const SizedBox(height: Gap.xxl),
              TextField(
                controller: _email,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Admin email',
                  hintText: 'you@example.com',
                ),
                onSubmitted: (_) => _primaryAction?.call(),
              ),
              if (!_useCode) ...[
                const SizedBox(height: Gap.lg),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                    ),
                  ),
                  onSubmitted: (_) => _signInWithPassword(),
                ),
              ],
              if (_useCode && _codeSent) ...[
                const SizedBox(height: Gap.lg),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(hintText: '------'),
                  onSubmitted: (_) => _verify(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: Gap.lg),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: Gap.xl),
              FilledButton(
                onPressed: _primaryAction,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_primaryLabel),
              ),
              if (_useCode && _codeSent)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _code.clear();
                            _error = null;
                          }),
                  child: const Text('Use a different email'),
                ),
              const SizedBox(height: Gap.sm),
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _useCode = !_useCode;
                            _codeSent = false;
                            _code.clear();
                            _password.clear();
                            _error = null;
                          }),
                  child: Text(_useCode
                      ? 'Use a password instead'
                      : 'Email me a code instead'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to normal sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
