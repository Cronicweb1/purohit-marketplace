import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../theme/app_theme.dart';

/// The screen between "which side are you on" and an actual form.
///
/// Splitting login and registration onto their own routes per role is what
/// makes the one-email-one-role rule explainable: by the time someone types an
/// address, the app already knows which side they claim to be on, so it can say
/// "this email is registered as a purohit" instead of a generic failure.
class RoleGatePage extends StatelessWidget {
  const RoleGatePage({super.key, required this.role});

  final UserRole role;

  bool get _isPurohit => role == UserRole.purohit;

  @override
  Widget build(BuildContext context) {
    final accent = _isPurohit ? AppColors.maroon : AppColors.saffron;
    final slug = _isPurohit ? 'purohit' : 'user';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isPurohit ? 'For purohits' : 'For families'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.xl, Gap.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      _isPurohit ? Icons.self_improvement : Icons.family_restroom,
                      size: 36,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  Text(
                    _isPurohit
                        ? 'Take bookings from\nfamilies near you'
                        : 'Book a verified purohit\nfor your ceremony',
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  Text(
                    _isPurohit
                        ? 'Create a purohit account to list your services, see '
                            'requests in your area and apply with your own '
                            'dakshina. Verification happens after you register.'
                        : 'Create an account to post the ritual you need, '
                            'compare verified purohits and message them before '
                            'you confirm anything.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: Gap.xxl),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: () => context.push('/register/$slug'),
                    child: const Text('Create an account'),
                  ),
                  const SizedBox(height: Gap.md),
                  OutlinedButton(
                    onPressed: () => context.push('/login/$slug'),
                    child: const Text('I already have an account'),
                  ),
                  const SizedBox(height: Gap.xl),
                  Container(
                    padding: const EdgeInsets.all(Gap.lg),
                    decoration: BoxDecoration(
                      color: AppColors.saffronTint,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppColors.saffronDark),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Text(
                            'One email belongs to one side of the app. If this '
                            'address is already registered as '
                            '${_isPurohit ? 'a family' : 'a purohit'}, use that '
                            'login instead — or register with a different '
                            'email.',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
