import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_providers.dart';
import '../../theme/app_theme.dart';

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
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
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
          padding: const EdgeInsets.all(Gap.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Gap.xxl),
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
                const SizedBox(height: Gap.xxl),
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
                const Text(
                  'We will email you a 6-digit code. No password to remember.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
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
                      : const Text('Send code'),
                ),
                const SizedBox(height: Gap.md),
                TextButton(
                  onPressed: () => context.go('/browse'),
                  child: const Text('Browse ceremonies without signing in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
