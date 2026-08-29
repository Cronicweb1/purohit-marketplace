import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../data/applications_repository.dart';
import '../../data/jobs_repository.dart';
import '../../data/messages_repository.dart';
import '../../models/application.dart';
import '../../models/job.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../../widgets/user_avatar.dart';

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobDetailProvider(jobId));
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceremony'),
        // This route sits on the root navigator, so it can be reached either by
        // a push (back pops) or by a go (nothing to pop - fall back to the
        // list the user most likely came from).
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
      body: job.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        ),
        data: (j) {
          if (j == null) {
            return const EmptyState(
              icon: Icons.visibility_off_outlined,
              title: 'Not visible to you',
              message:
                  'This ceremony either no longer exists, or row-level security '
                  'does not grant you access to it.',
            );
          }
          return _JobBody(job: j, isPurohit: session.isPurohit);
        },
      ),
      bottomNavigationBar: job.maybeWhen(
        data: (j) {
          if (j == null || !session.isPurohit) return const SizedBox.shrink();
          return _ApplyBar(job: j, canApply: session.canSeeJobFeed);
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _JobBody extends ConsumerWidget {
  const _JobBody({required this.job, required this.isPurohit});

  final Job job;
  final bool isPurohit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        Text(
          job.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          'Posted ${timeAgo(job.createdAt)}',
          style: const TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
        ),
        const SizedBox(height: Gap.xl),
        _FactRow(
          icon: Icons.currency_rupee,
          label: 'Budget',
          value: formatBudget(job.budget),
        ),
        _FactRow(
          icon: Icons.event,
          label: 'Date',
          value: '${formatDateRange(job.startDate, job.endDate)}'
              '  ·  ${daysUntil(job.startDate)}',
        ),
        if (job.ritualName != null)
          _FactRow(
            icon: Icons.auto_awesome,
            label: 'Ceremony',
            value: job.ritualName!,
          ),
        if (job.cityName != null)
          _FactRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: [job.cityName, job.cityState]
                .whereType<String>()
                .join(', '),
          ),
        _FactRow(
          icon: Icons.flag_outlined,
          label: 'Urgency',
          value: job.urgency.label,
        ),
        if ((job.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: Gap.xl),
          const Text(
            'Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            job.description!.trim(),
            style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.inkMuted),
          ),
        ],
        if (!isPurohit) ...[
          const SizedBox(height: Gap.xxl),
          const Text(
            'Applications',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Gap.sm),
          _Applicants(job: job),
        ],
        const SizedBox(height: Gap.xxl),
      ],
    );
  }
}

class _Applicants extends ConsumerWidget {
  const _Applicants({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(jobApplicationsProvider(job.id));

    return apps.when(
      loading: () => const TileSkeletonColumn(count: 2, padding: EdgeInsets.zero),
      error: (e, _) => Text(
        '$e',
        style: const TextStyle(fontSize: 13, color: AppColors.danger),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Text(
            'No purohit has applied yet. Verified purohits see your post in '
            'their feed.',
            style: TextStyle(fontSize: 13.5, color: AppColors.inkMuted, height: 1.4),
          );
        }
        return Column(
          children: [
            for (final a in list) _ApplicantTile(application: a, job: job),
          ],
        );
      },
    );
  }
}

class _ApplicantTile extends ConsumerStatefulWidget {
  const _ApplicantTile({required this.application, required this.job});

  final Application application;
  final Job job;

  @override
  ConsumerState<_ApplicantTile> createState() => _ApplicantTileState();
}

class _ApplicantTileState extends ConsumerState<_ApplicantTile> {
  bool _busy = false;

  Future<void> _openChat() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(messagesRepositoryProvider).openOrCreate(
            jobId: widget.job.id,
            panditId: widget.application.panditId,
          );
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      context.push('/messages/$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finalize() async {
    if (_busy) return;
    final a = widget.application;
    final name = a.panditName ?? 'this purohit';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm purohit'),
        content: Text(
          'Select $name for this ceremony?\n\n'
          'Every other applicant is marked not selected, the ceremony moves to '
          '"Purohit selected", and contact details are exchanged. This cannot '
          'be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(applicationsRepositoryProvider).finalize(
            applicationId: a.id,
            jobId: widget.job.id,
          );
      ref.invalidate(jobApplicationsProvider(widget.job.id));
      ref.invalidate(jobDetailProvider(widget.job.id));
      ref.invalidate(myJobsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name is confirmed for this ceremony.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final canFinalize = widget.job.status == JobStatus.open &&
        a.status != ApplicationStatus.withdrawn &&
        a.status != ApplicationStatus.rejected;

    return Card(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/purohit/${a.panditId}'),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: a.panditName ?? 'Purohit',
                    imageUrl: a.panditAvatarUrl,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.panditName ?? 'Purohit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (a.panditExperienceYears != null)
                              '${a.panditExperienceYears} yrs',
                            a.status.label,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.inkFaint,
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              // The quote is the number the family actually decides on, so it
              // gets its own row rather than being buried in the subtitle.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.md,
                  vertical: Gap.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.saffronTint,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: AppColors.saffronDark,
                    ),
                    const SizedBox(width: Gap.sm),
                    Text(
                      a.quotedFee == null
                          ? 'No amount quoted'
                          : 'Quoted ${formatMoney(a.quotedFee)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if ((a.message ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  a.message!.trim(),
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ],
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _openChat,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Message'),
                    ),
                  ),
                  if (canFinalize) ...[
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _finalize,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Select'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.inkFaint),
          const SizedBox(width: Gap.md),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.inkFaint),
            ),
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

class _ApplyBar extends ConsumerWidget {
  const _ApplyBar({required this.job, required this.canApply});

  final Job job;
  final bool canApply;

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final feeCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ApplySheet(
        jobId: job.id,
        feeCtrl: feeCtrl,
        msgCtrl: msgCtrl,
      ),
    );

    feeCtrl.dispose();
    msgCtrl.dispose();

    if (sent == true) {
      ref.invalidate(hasAppliedProvider(job.id));
      ref.invalidate(myApplicationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application sent.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(hasAppliedProvider(job.id));
    final already = applied.asData?.value ?? false;
    final closed = job.status != JobStatus.open;

    final String label;
    final VoidCallback? onPressed;
    if (!canApply) {
      label = 'Verification pending';
      onPressed = null;
    } else if (closed) {
      label = 'Closed';
      onPressed = null;
    } else if (already) {
      label = 'Applied';
      onPressed = null;
    } else {
      label = 'Apply';
      onPressed = () => _openSheet(context, ref);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}

class _ApplySheet extends ConsumerStatefulWidget {
  const _ApplySheet({
    required this.jobId,
    required this.feeCtrl,
    required this.msgCtrl,
  });

  final int jobId;
  final TextEditingController feeCtrl;
  final TextEditingController msgCtrl;

  @override
  ConsumerState<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends ConsumerState<_ApplySheet> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(applicationsRepositoryProvider).apply(
            jobId: widget.jobId,
            message: widget.msgCtrl.text,
            quotedFee: num.tryParse(widget.feeCtrl.text.trim()),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Gap.lg,
        right: Gap.lg,
        top: Gap.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + Gap.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send your quote',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Gap.lg),
          const Text('Your fee (₹)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: Gap.sm),
          TextField(
            controller: widget.feeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 5100'),
          ),
          const SizedBox(height: Gap.lg),
          const Text('Message to the family',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: Gap.sm),
          TextField(
            controller: widget.msgCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Which sampradaya you follow, what is included…',
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
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send application'),
          ),
        ],
      ),
    );
  }
}
