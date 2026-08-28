import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../data/applications_repository.dart';
import '../../data/jobs_repository.dart';
import '../../models/application.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';
import '../../widgets/states.dart';

/// Branch 1 of the shell. Means two different things depending on the role:
/// a family sees the ceremonies they posted, a purohit sees the jobs they bid on.
class MyWorkPage extends ConsumerWidget {
  const MyWorkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isPurohit = session.isPurohit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPurohit ? 'My applications' : 'My ceremonies'),
        automaticallyImplyLeading: false,
      ),
      body: isPurohit ? const _MyApplications() : const _MyJobs(),
    );
  }
}

class _MyJobs extends ConsumerWidget {
  const _MyJobs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myJobsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myJobsProvider),
      child: jobs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myJobsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.temple_hindu_outlined,
                  title: 'Nothing posted yet',
                  message:
                      'Post a ceremony from the Post tab. Verified purohits in '
                      'your city will see it and send you their quotes.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Gap.md),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final job = list[i];
              return JobCard(
                job: job,
                showStatus: true,
                onTap: () => context.push('/jobs/${job.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyApplications extends ConsumerWidget {
  const _MyApplications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(myApplicationsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myApplicationsProvider),
      child: apps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(myApplicationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.work_outline,
                  title: 'No applications yet',
                  message:
                      'Open Find work, pick a ceremony you can perform, and '
                      'send the family your quote.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Gap.md),
            itemCount: list.length,
            itemBuilder: (context, i) => _ApplicationCard(application: list[i]),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final Application application;

  Color get _statusColor => switch (application.status) {
        ApplicationStatus.selected => AppColors.success,
        ApplicationStatus.shortlisted => AppColors.warning,
        ApplicationStatus.rejected => AppColors.danger,
        _ => AppColors.inkMuted,
      };

  @override
  Widget build(BuildContext context) {
    final a = application;

    return Card(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/jobs/${a.jobId}'),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      a.jobTitle ?? 'Ceremony #${a.jobId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      a.status.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              Text(
                [
                  if (a.quotedFee != null) 'You quoted ${formatMoney(a.quotedFee)}',
                  'Sent ${timeAgo(a.createdAt)}',
                ].join('  ·  '),
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
              ),
              if (a.status == ApplicationStatus.selected) ...[
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Selected — the family\'s contact details are unlocked.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
