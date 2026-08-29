import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/portfolio_repository.dart';
import '../../data/profile_repository.dart';
import '../../data/storage_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../../widgets/user_avatar.dart';

/// Viewer mode: what a family sees about a purohit who applied to their job.
///
/// Everything here is already public by policy (`pandit_public_read`) or
/// world-readable (`profiles_read`). Date of birth, KYC documents, guru
/// references and contact details are deliberately absent - contact is gated
/// behind selection by `v_job_contacts`, and this page must not become a way
/// around that.
class PurohitPublicPage extends ConsumerWidget {
  const PurohitPublicPage({super.key, required this.panditId});

  final String panditId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicPurohitProvider(panditId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purohit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my-work');
            }
          },
        ),
      ),
      body: async.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(publicPurohitProvider(panditId)),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profile unavailable',
              message:
                  'This purohit is no longer listed, or their verification '
                  'has not been approved yet.',
            );
          }
          return _Body(panditId: panditId, data: data);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.panditId, required this.data});

  final String panditId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = data['profiles'];
    final city = data['cities'];
    final name = (profile is Map ? profile['full_name'] as String? : null) ??
        'Purohit';
    final avatar = profile is Map ? profile['avatar_url'] as String? : null;
    final cityName = city is Map
        ? [city['name'], city['state']]
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .join(', ')
        : null;

    final languages = (data['languages'] as List?)?.whereType<String>().toList()
        ?? const <String>[];
    final years = data['experience_years'] as int?;
    final baseFee = data['base_fee'];
    final approved = data['status'] == 'approved';
    final available = data['is_available'] == true;
    final radius = data['service_radius_km'] as int?;
    final bio = (data['bio'] as String?)?.trim();

    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        Row(
          children: [
            UserAvatar(name: name, imageUrl: avatar, radius: 34),
            const SizedBox(width: Gap.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (cityName != null && cityName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cityName,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.xs,
                    runSpacing: Gap.xs,
                    children: [
                      if (approved)
                        const _Tag(
                          label: 'Verified',
                          icon: Icons.verified,
                          tone: AppColors.success,
                        ),
                      _Tag(
                        label: available ? 'Available' : 'Busy',
                        icon: available
                            ? Icons.event_available_outlined
                            : Icons.event_busy_outlined,
                        tone: available
                            ? AppColors.saffronDark
                            : AppColors.inkMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.xl),
        _Fact(
          icon: Icons.workspace_premium_outlined,
          label: 'Experience',
          value: years == null ? 'Not stated' : '$years years',
        ),
        _Fact(
          icon: Icons.payments_outlined,
          label: 'Typical dakshina',
          value: baseFee == null
              ? 'Varies by ceremony'
              : 'from ${formatMoney(baseFee is num ? baseFee : null)}',
        ),
        _Fact(
          icon: Icons.translate,
          label: 'Languages',
          value: languages.isEmpty ? 'Not stated' : languages.join(', '),
        ),
        if (radius != null)
          _Fact(
            icon: Icons.travel_explore,
            label: 'Travels up to',
            value: '$radius km',
          ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: Gap.lg),
          const Text(
            'About',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Gap.sm),
          Text(bio, style: const TextStyle(height: 1.45)),
        ],
        const SizedBox(height: Gap.xl),
        const Text(
          'Work photos',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Gap.sm),
        _Portfolio(panditId: panditId),
        const SizedBox(height: Gap.xxl),
      ],
    );
  }
}

class _Portfolio extends ConsumerWidget {
  const _Portfolio({required this.panditId});

  final String panditId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioProvider(panditId));
    final storage = ref.watch(storageRepositoryProvider);

    return async.when(
      loading: () => const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Text(
        'Could not load photos.',
        style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Text(
            'No work photos yet.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: Gap.sm),
            itemBuilder: (context, i) {
              final url = storage.publicUrl(
                bucket: kProfileMediaBucket,
                path: items[i].objectPath,
              );
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: Container(
                  width: 130,
                  color: AppColors.saffronTint,
                  child: url == null
                      ? const Icon(Icons.image_outlined)
                      : Image.network(url, fit: BoxFit.cover),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.saffronDark),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon, required this.tone});

  final String label;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
