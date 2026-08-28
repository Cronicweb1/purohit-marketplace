import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session.dart';
import '../../core/supabase_providers.dart';
import '../../theme/app_theme.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _code.text.trim();
    if (token.length < 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await supabase.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: token,
      );
      await ref.read(sessionProvider.notifier).refresh();
      if (!mounted) return;
      // The router redirect decides where to land: onboarding if there is no
      // profiles row yet, otherwise straight into the app.
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'That code did not work. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await supabase.auth.signInWithOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('New code sent.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter code')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We sent a 6-digit code to ${widget.email}.',
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: Gap.xl),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: '------'),
                onSubmitted: (_) => _verify(),
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
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: Gap.sm),
              TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Resend code'),
              ),
              const SizedBox(height: Gap.xl),
              const Text(
                'No code? Check spam. If the email contains a link instead of a '
                'number, the Supabase email template still needs the {{ .Token }} '
                'variable.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
