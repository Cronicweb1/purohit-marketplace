import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/session.dart';
import '../../data/reference_repository.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_picker.dart';
import 'profile_media.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final session = ref.watch(sessionProvider);
    final profile = session.profile;
    final pandit = session.pandit;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Row(
            children: [
              AvatarEditor(
                name: profile?.fullName ?? t.guest,
                avatarUrl: profile?.avatarUrl,
              ),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? t.guest,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.isPurohit ? t.rolePurohit : t.roleUser,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.xl),
          if (pandit != null) _VerificationCard(pandit: pandit),
          const SizedBox(height: Gap.lg),
          _InfoTile(
            icon: Icons.mail_outline,
            label: t.labelEmail,
            value: session.email ?? '—',
          ),
          if (profile?.cityId != null)
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: t.labelCity,
              value: ref.watch(citiesProvider).maybeWhen(
                    data: (list) {
                      for (final c in list) {
                        if (c.id == profile!.cityId) return c.label;
                      }
                      return '—';
                    },
                    orElse: () => '…',
                  ),
            ),
          if (pandit?.dob != null)
            _InfoTile(
              icon: Icons.cake_outlined,
              label: t.labelDateOfBirth,
              value: '${formatDate(pandit!.dob!)}  '
                  '\u00b7  ${t.yearsCount(ageFrom(pandit.dob!))}',
            ),
          if (pandit?.experienceYears != null)
            _InfoTile(
              icon: Icons.workspace_premium_outlined,
              label: t.labelExperience,
              value: t.yearsCount(pandit!.experienceYears!),
            ),
          if ((pandit?.bio ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            Text(t.about,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.sm),
            Text(
              pandit!.bio!.trim(),
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.inkMuted),
            ),
          ],
          if (session.isPurohit && pandit != null) ...[
            const SizedBox(height: Gap.xl),
            Text(
              t.workPhotos,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Gap.xs),
            Text(
              t.workPhotosHint,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: Gap.sm),
            PortfolioEditor(panditId: pandit.id),
          ],
          const SizedBox(height: Gap.xxl),
          if (session.isPurohit)
            FilledButton.tonalIcon(
              onPressed: () => context.push('/register-purohit'),
              icon: Icon(
                pandit == null
                    ? Icons.how_to_reg_outlined
                    : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                pandit == null ? t.registerAsPurohit : t.editPurohitDetails,
              ),
            ),
          if (session.isAdmin) ...[
            const SizedBox(height: Gap.sm),
            OutlinedButton.icon(
              onPressed: () => context.push('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: Text(t.verificationConsole),
            ),
          ],
          const SizedBox(height: Gap.sm),
          // Unconditional on purpose: families, purohits and admins all need to
          // be able to change the interface language, so this sits outside the
          // role guards above.
          const LanguageTile(),
          const SizedBox(height: Gap.lg),
          OutlinedButton.icon(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(t.signOut),
          ),
          const SizedBox(height: Gap.xl),
          Center(
            child: Text(
              t.earlyBuild,
              style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
            ),
          ),
          const SizedBox(height: Gap.xxl),
        ],
      ),
    );
  }
}

class _VerificationCard extends ConsumerWidget {
  const _VerificationCard({required this.pandit});

  final PanditProfile pandit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final approved = pandit.status == VerificationStatus.approved;
    final rejected = pandit.status == VerificationStatus.rejected;
    final color = approved
        ? AppColors.success
        : rejected
            ? AppColors.danger
            : AppColors.warning;

    final message = approved
        ? t.verificationApprovedBody
        : rejected
            ? t.verificationRejectedBody
            : t.verificationPendingBody;

    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved
                ? Icons.verified
                : rejected
                    ? Icons.cancel_outlined
                    : Icons.hourglass_top,
            size: 20,
            color: color,
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pandit.status.label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 13, height: 1.45, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkFaint),
          const SizedBox(width: Gap.md),
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.inkFaint)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
