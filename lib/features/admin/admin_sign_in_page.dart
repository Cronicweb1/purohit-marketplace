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
/// Same email-OTP mechanism as the public sign-in — a separate password system
/// for admins would be a second thing to leak. What differs is the destination:
/// this screen lands on the verification console and refuses to continue if the
/// token does not carry the admin role, so an admin never has to hunt for the
/// console inside the family/purohit UI.
///
/// Both steps live on one screen deliberately: pushing to `/verify` would send
/// the user through the ordinary post-login redirect and lose the intent.
class AdminSignInPage extends ConsumerStatefulWidget {
  const AdminSignInPage({super.key});

  @override
  ConsumerState<AdminSignInPage> createState() => _AdminSignInPageState();
}

class _AdminSignInPageState extends ConsumerState<AdminSignInPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
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
      await supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'That code did not work. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin sign in')),
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
                decoration: const InputDecoration(
                  labelText: 'Admin email',
                  hintText: 'you@example.com',
                ),
                onSubmitted: (_) => _send(),
              ),
              if (_codeSent) ...[
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
                onPressed: _busy ? null : (_codeSent ? _verify : _send),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_codeSent ? 'Verify and open console' : 'Send code'),
              ),
              if (_codeSent)
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
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('Back to normal sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
