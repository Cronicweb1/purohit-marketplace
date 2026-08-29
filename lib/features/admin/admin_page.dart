import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../data/verification_repository.dart';
import '../../models/profile.dart' show formatDate, ageFrom;
import '../../models/verification.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';

/// The admin verification console.
///
/// Intentionally one screen, not a dashboard. The only thing an admin must do
/// inside the app is turn a pending purohit into an approved (or rejected) one;
/// anything analytical is better done in the Supabase SQL editor.
///
/// Access is gated twice, and the second gate is the real one:
///   * the UI hides itself unless the JWT carries `app_metadata.role = 'admin'`
///   * `pandit_public_read`, `certs_owner`, `guru_owner`, `ve_insert` and the
///     `guard_pandit_status()` trigger all re-check `is_admin()` server-side.
/// A tampered client therefore gets an empty list and a failed write, not data.
class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  static const _filters = <String, String>{
    'pending': 'Pending',
    'under_review': 'Under review',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (!session.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to the app',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jobs'),
          ),
          title: const Text('Admin'),
        ),
        body: const _NotAnAdmin(),
      );
    }

    final filter = ref.watch(adminQueueFilterProvider);
    final queue = ref.watch(adminQueueProvider);

    return Scaffold(
      appBar: AppBar(
        // /admin sits outside the StatefulShellRoute, so there is no bottom
        // navigation bar here, and admin sign-in lands with `go` rather than
        // `push`, so there is no back stack either. Without these two controls
        // an admin who signs in through /admin-sign-in has no way out of this
        // screen short of killing the app.
        leading: IconButton(
          tooltip: 'Back to the app',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/jobs'),
        ),
        title: const Text('Verification console'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminQueueProvider),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'app') {
                context.go('/jobs');
              } else {
                ref.read(sessionProvider.notifier).signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'app',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.home_outlined),
                  title: Text('Back to the app'),
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              children: [
                for (final entry in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.sm, top: Gap.sm),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: filter == entry.key,
                      onSelected: (_) => ref
                          .read(adminQueueFilterProvider.notifier)
                          .state = entry.key,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.hairline),
          Expanded(
            // Pull-to-refresh wraps every branch: an admin who lands on an
            // empty or failed queue still expects a pull to retry it.
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminQueueProvider),
              color: AppColors.saffron,
              child: queue.when(
                loading: () => const TileListSkeleton(count: 4),
                error: (e, _) => RefreshableBody(
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(adminQueueProvider),
                  ),
                ),
                data: (cases) {
                  if (cases.isEmpty) {
                    return RefreshableBody(
                      child: EmptyState(
                        icon: Icons.verified_outlined,
                        title: 'Queue is clear',
                        message:
                            'Nothing ${_filters[filter]!.toLowerCase()}. Pull '
                            'down to check again.',
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      Gap.lg,
                      Gap.lg,
                      Gap.lg,
                      Gap.xxl,
                    ),
                    itemCount: cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
                    itemBuilder: (_, i) => _CaseCard(item: cases[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends ConsumerStatefulWidget {
  const _CaseCard({required this.item});
  final VerificationCase item;

  @override
  ConsumerState<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends ConsumerState<_CaseCard> {
  bool _busy = false;

  Future<void> _decide(String to) async {
    final item = widget.item;

    // Rejecting without a reason is unusable for the purohit, who then has no
    // idea what to fix. Approving without proof defeats the whole queue.
    String? reason;
    if (to == 'rejected') {
      reason = await _askReason();
      if (reason == null) return;
    } else if (to == 'approved' && !item.hasProof) {
      final ok = await _confirmNoProof();
      if (ok != true) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(verificationRepositoryProvider).decide(
            panditId: item.panditId,
            fromStatus: item.status,
            toStatus: to,
            reason: reason,
          );
      ref.invalidate(adminQueueProvider);
      if (!mounted) return;
      showAppSnack(
        context,
        '${item.fullName} marked $to.',
        tone: to == 'rejected' ? SnackTone.neutral : SnackTone.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Failed: $e', tone: SnackTone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason for rejection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Certificate could not be verified with the institution.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool?> _confirmNoProof() => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No proof on file'),
          content: const Text(
            'This purohit has neither a certificate nor a guru reference. '
            'Approve anyway?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Approve')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Theme(
        // The default divider on an ExpansionTile fights the card border.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          childrenPadding:
              const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
          title: Text(item.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [
                if (item.cityLabel != null) item.cityLabel!,
                if (item.experienceYears != null)
                  '${item.experienceYears} yrs',
                item.hasProof ? 'proof attached' : 'no proof',
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
          children: [
            if ((item.bio ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(item.bio!,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: AppColors.inkMuted)),
              ),
              const SizedBox(height: Gap.md),
            ],
            if (item.dob != null) ...[
              _Row('Date of birth',
                  '${formatDate(item.dob!)} (${ageFrom(item.dob!)} years)'),
              const SizedBox(height: Gap.sm),
            ],
            if (item.languages.isNotEmpty) ...[
              _Row('Languages', item.languages.join(', ')),
              const SizedBox(height: Gap.sm),
            ],
            for (final d in item.kycDocuments) ...[
              _ProofBlock(
                icon: Icons.badge_outlined,
                title: '${d.roleLabel} \u00b7 ${d.typeLabel}',
                lines: [
                  'File: ${d.storagePath}',
                  if (d.sizeBytes != null) d.readableSize,
                ],
              ),
              const SizedBox(height: Gap.sm),
            ],
            if (!item.hasIdentityDocument) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No ID card on file. This purohit registered before ID '
                  'upload existed, or skipped it.',
                  style: TextStyle(fontSize: 13, color: AppColors.warning),
                ),
              ),
              const SizedBox(height: Gap.sm),
            ],
            for (final c in item.certificates) ...[
              _ProofBlock(
                icon: Icons.workspace_premium_outlined,
                title: '${c.kind} · ${c.institution}',
                lines: [
                  if (c.issuedOn != null)
                    'Issued ${c.issuedOn!.year}-'
                        '${c.issuedOn!.month.toString().padLeft(2, '0')}-'
                        '${c.issuedOn!.day.toString().padLeft(2, '0')}',
                  c.hasDocument
                      ? 'Document: ${c.storagePath}'
                      : 'Document not uploaded yet',
                ],
              ),
              const SizedBox(height: Gap.sm),
            ],
            for (final g in item.guruReferences) ...[
              _ProofBlock(
                icon: Icons.self_improvement_outlined,
                title: g.guruName,
                lines: [
                  if (g.gurukulName != null) g.gurukulName!,
                  if (g.yearsStudied != null)
                    'Studied ${g.yearsStudied} years',
                  if (g.hasPhone) 'Phone: ${g.guruPhone}',
                  if (g.notes != null) g.notes!,
                ],
              ),
              const SizedBox(height: Gap.sm),
            ],
            if (!item.hasProof)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No certificate or guru reference submitted.',
                  style: TextStyle(fontSize: 13, color: AppColors.warning),
                ),
              ),
            const SizedBox(height: Gap.md),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  if (item.status != 'under_review')
                    OutlinedButton(
                      onPressed: () => _decide('under_review'),
                      child: const Text('Under review'),
                    ),
                  if (item.status != 'approved')
                    FilledButton(
                      onPressed: () => _decide('approved'),
                      child: const Text('Approve'),
                    ),
                  if (item.status != 'rejected')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      onPressed: () => _decide('rejected'),
                      child: const Text('Reject'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text('$label: $value',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
      );
}

class _ProofBlock extends StatelessWidget {
  const _ProofBlock({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.saffronDark),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(l,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkMuted)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _NotAnAdmin extends StatelessWidget {
  const _NotAnAdmin();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 40, color: AppColors.inkFaint),
              const SizedBox(height: Gap.lg),
              const Text('Admins only',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: Gap.sm),
              const Text(
                'This account does not carry the admin role. The role lives in '
                'the auth token and can only be granted from the Supabase '
                'dashboard, so it cannot be requested from inside the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.inkMuted),
              ),
              const SizedBox(height: Gap.xl),
              OutlinedButton(
                onPressed: () => context.go('/jobs'),
                child: const Text('Back to the app'),
              ),
            ],
          ),
        ),
      );
}
