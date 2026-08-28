import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../data/jobs_repository.dart';
import '../../data/reference_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';
import '../../widgets/states.dart';
import '../rituals/rituals_page.dart';

/// Branch 0. Same tab, different content per role — a family browses ceremonies
/// and purohits, a purohit browses open jobs.
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session.isPurohit ? const JobsFeedView() : const RitualsView();
  }
}

class JobsFeedView extends ConsumerStatefulWidget {
  const JobsFeedView({super.key});

  @override
  ConsumerState<JobsFeedView> createState() => _JobsFeedViewState();
}

class _JobsFeedViewState extends ConsumerState<JobsFeedView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final jobs = ref.watch(openJobsProvider);
    final rituals = ref.watch(ritualsProvider);
    final filter = ref.watch(jobFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find work'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search ceremonies, e.g. Griha Pravesh',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _search.clear();
                          ref.read(jobFilterProvider.notifier).setQuery('');
                        },
                      ),
              ),
              onSubmitted: (v) =>
                  ref.read(jobFilterProvider.notifier).setQuery(v),
            ),
          ),
          rituals.maybeWhen(
            data: (list) {
              final top = list.where((r) => r.bookable).take(10).toList();
              if (top.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  itemCount: top.length,
                  separatorBuilder: (_, __) => const SizedBox(width: Gap.sm),
                  itemBuilder: (ctx, i) {
                    final r = top[i];
                    final selected = filter.ritualId == r.id;
                    return FilterChip(
                      label: Text(r.name),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(jobFilterProvider.notifier)
                          .toggleRitual(r.id),
                    );
                  },
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          if (!session.canSeeJobFeed)
            const NoticeBanner(
              icon: Icons.hourglass_top,
              message:
                  'Your purohit listing is awaiting verification. Job posts stay '
                  'hidden until an admin approves you — this is enforced by the '
                  'database, so the list below will be empty until then.',
            ),
          Expanded(
            child: jobs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(openJobsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.inbox_outlined,
                    title: session.canSeeJobFeed
                        ? 'No open jobs match'
                        : 'Nothing to show yet',
                    message: session.canSeeJobFeed
                        ? 'Try clearing filters, or check back tomorrow.'
                        : 'Once your listing is verified, ceremonies posted by '
                            'families will appear here.',
                    action: filter.isEmpty
                        ? null
                        : OutlinedButton(
                            onPressed: () {
                              _search.clear();
                              ref.read(jobFilterProvider.notifier).clear();
                            },
                            child: const Text('Clear filters'),
                          ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(openJobsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final job = list[i];
                      return JobCard(
                        job: job,
                        onTap: () => context.push('/jobs/${job.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
