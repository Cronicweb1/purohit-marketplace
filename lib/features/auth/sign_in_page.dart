import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_intent.dart';
import '../../core/supabase_providers.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';

/// Which door the user came through. Both send the same email OTP — Supabase
/// creates the account on first code — so the only real difference is where
/// they land afterwards.
enum _Mode { signIn, registerPurohit }

/// Email OTP, not SMS.
///
/// India's TRAI DLT regime requires every transactional SMS sender to register
/// a header and template with a telecom operator — weeks of paperwork and a
/// registered business entity. Email OTP needs neither and works today. The
/// call is isolated here so swapping in phone OTP later touches one file.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _Mode _mode = _Mode.signIn;
  bool _sending = false;
  String? _error;

  bool get _isRegister => _mode == _Mode.registerPurohit;

  @override
  void dispose() {
    _email.dispose();
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

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    if (!supabaseReady) {
      setState(() => _error = 'Supabase is not configured in this build.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final email = _email.text.trim();
    try {
      await supabase.auth.signInWithOtp(email: email);
      // Remembered across the OTP hop: onboarding preselects the purohit role
      // and VerifyOtpPage routes an already-onboarded user straight to
      // /register-purohit instead of dropping them on the jobs feed.
      AuthIntent.remember(_isRegister ? UserRole.purohit : null);
      if (!mounted) return;
      context.push('/verify?email=${Uri.encodeComponent(email)}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
                          'Enter your email to get a code, then tell us about your '
                          'experience and add a Gurukul certificate or guru '
                          'reference. An admin reviews it before your listing goes '
                          'live — you can browse in the meantime.',
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
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return 'That does not look like an email address';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _send(),
                ),
                const SizedBox(height: Gap.md),
                Text(
                  _isRegister
                      ? 'We will email you a 6-digit code, then walk you through '
                          'your purohit profile. No password to remember.'
                      : 'We will email you a 6-digit code. No password to remember.',
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
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isRegister ? 'Continue as a purohit' : 'Sign in'),
                ),
                const SizedBox(height: Gap.md),
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
