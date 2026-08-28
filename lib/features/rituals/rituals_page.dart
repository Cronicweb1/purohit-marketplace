import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../data/profile_repository.dart';
import '../../data/reference_repository.dart';
import '../../models/ritual.dart';
import '../../theme/app_theme.dart';
import '../../widgets/states.dart';

/// The only surface that works before sign-in.
///
/// `rituals`, `cities` and approved `pandit_profiles` are the three things the
/// RLS policies expose to the anon key. Everything else needs a session, so this
/// is what an unauthenticated visitor is allowed to see — and it is enough to
/// show what the app is for before asking for an email.
class RitualsView extends ConsumerStatefulWidget {
  const RitualsView({super.key, this.standalone = false});

  /// True when reached at `/browse` while signed out — adds a sign-in action.
  final bool standalone;

  @override
  ConsumerState<RitualsView> createState() => _RitualsViewState();
}

class _RitualsViewState extends ConsumerState<RitualsView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final rituals = ref.watch(bookableRitualsProvider);
    final pandits = ref.watch(approvedPanditsProvider);
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.standalone)
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('Sign in'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ritualsProvider);
          ref.invalidate(approvedPanditsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search a ceremony',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            if (session.status == SessionStatus.signedOut)
              const SliverToBoxAdapter(
                child: NoticeBanner(
                  icon: Icons.lock_outline,
                  message:
                      'Sign in to post a ceremony and receive quotes from '
                      'verified purohits.',
                ),
              ),
            const SliverToBoxAdapter(child: SectionHeader(title: 'Ceremonies')),
            rituals.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(Gap.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(ritualsProvider),
                ),
              ),
              data: (list) {
                final filtered =
                    list.where((r) => r.matches(_query)).toList();
                if (filtered.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No ceremony matches',
                      message: 'Try a shorter search, or the Hindi name.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Gap.sm),
                    itemBuilder: (ctx, i) => _RitualTile(
                      ritual: filtered[i],
                      onTap: () {
                        if (session.status == SessionStatus.ready &&
                            !session.isPurohit) {
                          context.go('/post?ritual=${filtered[i].id}');
                        } else {
                          context.go('/sign-in');
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Verified purohits'),
            ),
            pandits.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(Gap.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(Gap.lg),
                  child: Text(
                    'Could not load purohits right now.',
                    style: TextStyle(color: AppColors.inkFaint),
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.person_search,
                      title: 'No verified purohits yet',
                      message:
                          'Listings appear here once an admin approves them.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Gap.sm),
                    itemBuilder: (ctx, i) => _PanditTile(row: list[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualTile extends StatelessWidget {
  const _RitualTile({required this.ritual, required this.onTap});

  final Ritual ritual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = ritual.typicalDurationMinutes;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.xs,
        ),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.marigold.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            initialsOf(ritual.name),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.saffronDark,
            ),
          ),
        ),
        title: Text(
          ritual.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          [
            if (ritual.nameHi != null) ritual.nameHi!,
            if (ritual.isMultiDay)
              'Multi-day'
            else if (duration != null)
              '${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)} hr',
          ].join(' · '),
          style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint),
      ),
    );
  }
}

class _PanditTile extends StatelessWidget {
  const _PanditTile({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final profile = row['profiles'];
    final name = profile is Map ? '${profile['full_name'] ?? 'Purohit'}' : 'Purohit';
    final years = row['experience_years'];
    final fee = row['base_fee'];
    final bio = row['bio'];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.saffron.withValues(alpha: 0.16),
              child: Text(
                initialsOf(name),
                style: const TextStyle(
                  color: AppColors.saffronDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: Gap.xs),
                      const Icon(Icons.verified,
                          size: 15, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (years != null) '$years yrs experience',
                      if (fee != null) 'from ${formatMoney(fee as num)}',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  if (bio is String && bio.trim().isNotEmpty) ...[
                    const SizedBox(height: Gap.sm),
                    Text(
                      bio.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
