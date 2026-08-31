import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/session.dart';
import '../../data/jobs_repository.dart';
import '../../data/reference_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';
import '../../widgets/skeletons.dart';
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Restore what the user typed last time this tab was alive, so switching
    // to Profile and back does not silently reset their search.
    _search.text = ref.read(jobFilterProvider).query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Filters as you type. A keystroke-per-query would thrash the provider, so
  /// the last keystroke wins after a short pause — the Upwork behaviour.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(jobFilterProvider.notifier).setQuery(value);
    });
  }

  void _clearAll() {
    _debounce?.cancel();
    _search.clear();
    ref.read(jobFilterProvider.notifier).clear();
  }

  Future<void> _refresh() async {
    ref.invalidate(openJobsProvider);
    await ref.read(openJobsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final jobs = ref.watch(openJobsProvider);
    final rituals = ref.watch(ritualsProvider);
    final filter = ref.watch(jobFilterProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.findWork),
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
                hintText: t.searchCeremoniesHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _debounce?.cancel();
                          _search.clear();
                          ref.read(jobFilterProvider.notifier).setQuery('');
                        },
                      ),
              ),
              onChanged: _onQueryChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                ref.read(jobFilterProvider.notifier).setQuery(v);
              },
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
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.saffronDark
                            : AppColors.ink,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.saffron
                            : AppColors.hairline,
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(jobFilterProvider.notifier)
                            .toggleRitual(r.id);
                      },
                    );
                  },
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          if (!session.canSeeJobFeed)
            NoticeBanner(
              icon: Icons.hourglass_top,
              message: t.feedAwaitingVerificationBody,
            ),
          // A count plus a one-tap escape hatch. Filters that cannot be seen
          // or undone are the fastest way to make a feed look broken.
          jobs.maybeWhen(
            data: (list) => _ResultBar(
              count: list.length,
              filtered: !filter.isEmpty,
              onClear: _clearAll,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            // The refresher wraps every state, not just the happy one, so a
            // pull still works when the list is empty or the request failed.
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.saffron,
              child: jobs.when(
                loading: () => const JobListSkeleton(),
                error: (e, _) => RefreshableBody(
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(openJobsProvider),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return RefreshableBody(
                      child: EmptyState(
                        icon: Icons.inbox_outlined,
                        title: session.canSeeJobFeed
                            ? t.noOpenJobsMatch
                            : t.nothingToShowYet,
                        message: session.canSeeJobFeed
                            ? t.noOpenJobsMatchBody
                            : t.feedLockedBody,
                        action: filter.isEmpty
                            ? null
                            : OutlinedButton(
                                onPressed: _clearAll,
                                child: Text(t.clearFilters),
                              ),
                      ),
                    );
                  }

                  return ListView.separated(
                    key: const PageStorageKey('jobs-feed'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      Gap.lg,
                      Gap.md,
                      Gap.lg,
                      Gap.xxl,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
                    itemBuilder: (ctx, i) {
                      final job = list[i];
                      return JobCard(
                        job: job,
                        onTap: () => context.push('/jobs/${job.id}'),
                      );
                    },
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

class _ResultBar extends ConsumerWidget {
  const _ResultBar({
    required this.count,
    required this.filtered,
    required this.onClear,
  });

  final int count;
  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.openJobsCount(count),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          if (filtered)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: Text(t.clearAction),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.saffronDark,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
