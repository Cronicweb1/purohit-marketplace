import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/job.dart';
import '../models/application.dart';
import 'applications_repository.dart';

const _jobSelect =
    'id, title, description, start_date, end_date, created_at, urgency, '
    'status, budget, rituals(name), cities(name, state)';

class JobFilter {
  const JobFilter({this.query = '', this.ritualId, this.cityId});

  final String query;
  final int? ritualId;
  final int? cityId;

  JobFilter copyWith({
    String? query,
    int? ritualId,
    int? cityId,
    bool clearRitual = false,
    bool clearCity = false,
  }) =>
      JobFilter(
        query: query ?? this.query,
        ritualId: clearRitual ? null : (ritualId ?? this.ritualId),
        cityId: clearCity ? null : (cityId ?? this.cityId),
      );

  bool get isEmpty => query.isEmpty && ritualId == null && cityId == null;
}

class JobsRepository {
  const JobsRepository();

  /// The purohit-facing feed.
  ///
  /// Returns [] for anyone the `jobs_read` policy does not admit — an
  /// unauthenticated user, or a purohit whose `status` is not `approved`. That
  /// is a database guarantee, not a UI choice; do not try to work around it.
  Future<List<Job>> openJobs(JobFilter filter) async {
    if (!supabaseReady) return const [];

    var q = supabase.from('jobs').select(_jobSelect).eq('status', 'open');

    if (filter.ritualId != null) q = q.eq('ritual_id', filter.ritualId!);
    if (filter.cityId != null) q = q.eq('city_id', filter.cityId!);
    if (filter.query.trim().isNotEmpty) {
      final term = filter.query.trim().replaceAll(',', ' ');
      q = q.or('title.ilike.%$term%,description.ilike.%$term%');
    }

    final res = await q.order('created_at', ascending: false).limit(50);
    return (res as List)
        .map((e) => Job.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Jobs posted by the signed-in family.
  Future<List<Job>> myJobs() async {
    final uid = currentUserId;
    if (uid == null) return const [];

    final res = await supabase
        .from('jobs')
        .select(_jobSelect)
        .eq('family_id', uid)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => Job.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Job?> byId(int id) async {
    if (!supabaseReady) return null;
    final res =
        await supabase.from('jobs').select(_jobSelect).eq('id', id).maybeSingle();
    return res == null ? null : Job.fromMap(Map<String, dynamic>.from(res));
  }

  Future<Job> create({
    required String title,
    required String? description,
    required DateTime startDate,
    DateTime? endDate,
    int? ritualId,
    int? cityId,
    num? budget,
    JobUrgency urgency = JobUrgency.scheduled,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Sign in before posting a job.');
    }

    final res = await supabase
        .from('jobs')
        .insert({
          'family_id': uid,
          'title': title,
          'description': description,
          'start_date': _date(startDate),
          if (endDate != null) 'end_date': _date(endDate),
          if (ritualId != null) 'ritual_id': ritualId,
          if (cityId != null) 'city_id': cityId,
          if (budget != null) 'budget': budget,
          'urgency': urgency.name,
        })
        .select(_jobSelect)
        .single();

    return Job.fromMap(Map<String, dynamic>.from(res));
  }

  /// `date` columns reject a full ISO timestamp with a timezone offset.
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

final jobsRepositoryProvider = Provider<JobsRepository>((ref) => const JobsRepository());

final jobFilterProvider = NotifierProvider<JobFilterController, JobFilter>(
  JobFilterController.new,
);

class JobFilterController extends Notifier<JobFilter> {
  @override
  JobFilter build() => const JobFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void toggleRitual(int id) => state = state.ritualId == id
      ? state.copyWith(clearRitual: true)
      : state.copyWith(ritualId: id);

  void toggleCity(int id) => state =
      state.cityId == id ? state.copyWith(clearCity: true) : state.copyWith(cityId: id);

  void clear() => state = const JobFilter();
}

final openJobsProvider = FutureProvider<List<Job>>((ref) {
  final filter = ref.watch(jobFilterProvider);
  return ref.watch(jobsRepositoryProvider).openJobs(filter);
});

final myJobsProvider =
    FutureProvider<List<Job>>((ref) => ref.watch(jobsRepositoryProvider).myJobs());

final jobDetailProvider = FutureProvider.family<Job?, int>(
  (ref, id) => ref.watch(jobsRepositoryProvider).byId(id),
);


/// Jobs where the signed-in purohit was selected. The page intentionally derives
/// this from the application status, so a job cannot appear here merely because
/// it was viewed or applied to; it enters this list only after selection.
final purohitJobsProvider = FutureProvider<List<Job>>((ref) async {
  final applications = await ref.watch(myApplicationsProvider.future);
  final selected = applications
      .where((application) => application.status == ApplicationStatus.selected)
      .toList();
  final repository = ref.watch(jobsRepositoryProvider);
  final jobs = await Future.wait(selected.map((a) => repository.byId(a.jobId)));
  return jobs.whereType<Job>().toList();
});
