import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../data/reference_repository.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profile = session.profile;
    final pandit = session.pandit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.saffron.withValues(alpha: 0.16),
                child: Text(
                  initialsOf(profile?.fullName ?? 'Guest'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.saffronDark,
                  ),
                ),
              ),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? 'Guest',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.isPurohit ? 'Purohit' : 'Family',
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
            label: 'Email',
            value: session.email ?? '—',
          ),
          if (profile?.cityId != null)
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'City',
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
          if (pandit?.experienceYears != null)
            _InfoTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Experience',
              value: '${pandit!.experienceYears} years',
            ),
          if ((pandit?.bio ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            const Text('About',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.sm),
            Text(
              pandit!.bio!.trim(),
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.inkMuted),
            ),
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
                pandit == null
                    ? 'Register as a purohit'
                    : 'Edit purohit details',
              ),
            ),
          if (session.isAdmin) ...[
            const SizedBox(height: Gap.sm),
            OutlinedButton.icon(
              onPressed: () => context.push('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text('Verification console'),
            ),
          ],
          const SizedBox(height: Gap.lg),
          OutlinedButton.icon(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: Gap.xl),
          const Center(
            child: Text(
              'Purohit Marketplace · early build',
              style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
            ),
          ),
          const SizedBox(height: Gap.xxl),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.pandit});

  final PanditProfile pandit;

  @override
  Widget build(BuildContext context) {
    final approved = pandit.status == VerificationStatus.approved;
    final rejected = pandit.status == VerificationStatus.rejected;
    final color = approved
        ? AppColors.success
        : rejected
            ? AppColors.danger
            : AppColors.warning;

    final message = approved
        ? 'You are verified. Open ceremonies are visible in Find work.'
        : rejected
            ? 'Your verification was not approved. Reply to the email we sent '
                'to appeal.'
            : 'Verification pending. Until an admin approves you, the job feed '
                'stays empty — that rule lives in the database, not the app.';

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
