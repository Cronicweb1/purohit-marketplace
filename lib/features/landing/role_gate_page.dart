import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_controller.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_picker.dart';

/// The screen between "which side are you on" and an actual form.
///
/// Splitting login and registration onto their own routes per role is what
/// makes the one-email-one-role rule explainable: by the time someone types an
/// address, the app already knows which side they claim to be on, so it can say
/// "this email is registered as a purohit" instead of a generic failure.
class RoleGatePage extends ConsumerWidget {
  const RoleGatePage({super.key, required this.role});

  final UserRole role;

  bool get _isPurohit => role == UserRole.purohit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final accent = _isPurohit ? AppColors.maroon : AppColors.saffron;
    final slug = _isPurohit ? 'purohit' : 'user';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isPurohit ? t.gateForPurohits : t.gateForFamilies),
        actions: const [LanguageButton(), SizedBox(width: Gap.sm)],
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
                    _isPurohit ? t.gatePurohitHeadline : t.gateFamilyHeadline,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  Text(
                    _isPurohit ? t.gatePurohitBody : t.gateFamilyBody,
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
                    child: Text(t.createAccount),
                  ),
                  const SizedBox(height: Gap.md),
                  OutlinedButton(
                    onPressed: () => context.push('/login/$slug'),
                    child: Text(t.alreadyHaveAccount),
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
                            t.oneEmailNotice(
                              _isPurohit ? t.sideFamily : t.sidePurohit,
                            ),
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
