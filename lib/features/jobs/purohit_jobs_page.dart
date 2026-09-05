import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/jobs_repository.dart';
import '../../models/job.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../shell/home_shell.dart';

/// Purohit-only work history: jobs the purohit was selected for, grouped into
/// upcoming, currently running, and past work.
class PurohitJobsPage extends ConsumerWidget {
  const PurohitJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final jobs = ref.watch(purohitJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.navMyJobs),
        automaticallyImplyLeading: false,
        leading: const ShellProfileButton(),
      ),
      body: RefreshIndicator(
        color: AppColors.saffron,
        onRefresh: () async {
          ref.invalidate(purohitJobsProvider);
          await ref.read(purohitJobsProvider.future);
        },
        child: jobs.when(
          loading: () => const TileListSkeleton(count: 3),
          error: (e, _) => RefreshableBody(
            child: ErrorView(
              error: e,
              onRetry: () => ref.invalidate(purohitJobsProvider),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return RefreshableBody(
                child: EmptyState(
                  icon: Icons.work_history_outlined,
                  title: 'No selected jobs yet',
                  message:
                      'Jobs where a family selects you will appear here.',
                ),
              );
            }

            final now = DateTime.now();
            final upcoming = list
                .where((job) => job.status == JobStatus.assigned &&
                    job.startDate.isAfter(now))
                .toList();
            final current = list
                .where((job) => job.status == JobStatus.assigned &&
                    !job.startDate.isAfter(now) &&
                    (job.endDate == null || !job.endDate!.isBefore(now)))
                .toList();
            final past = list
                .where((job) => !upcoming.contains(job) && !current.contains(job))
                .toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
              children: [
                if (current.isNotEmpty) ...[
                  const _SectionTitle('Currently doing'),
                  ...current.map((job) => _PurohitJobCard(job: job)),
                ],
                if (upcoming.isNotEmpty) ...[
                  const _SectionTitle('Upcoming'),
                  ...upcoming.map((job) => _PurohitJobCard(job: job)),
                ],
                if (past.isNotEmpty) ...[
                  const _SectionTitle('Past'),
                  ...past.map((job) => _PurohitJobCard(job: job)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, Gap.sm, 0, Gap.sm),
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      );
}

class _PurohitJobCard extends StatelessWidget {
  const _PurohitJobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (job.status) {
      JobStatus.assigned => AppColors.success,
      JobStatus.completed => AppColors.inkMuted,
      JobStatus.cancelled => AppColors.danger,
      JobStatus.open => AppColors.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: Gap.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/jobs/${job.id}'),
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
                      job.title,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      switch (job.status) {
                        JobStatus.assigned => 'Purohit selected',
                        JobStatus.completed => 'Completed',
                        JobStatus.cancelled => 'Cancelled',
                        JobStatus.open => 'Open',
                      },
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              Text(
                [
                  formatDate(job.startDate),
                  if (job.locationLabel != null) job.locationLabel!,
                ].join('  ·  '),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
