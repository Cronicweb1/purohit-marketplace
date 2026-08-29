import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/application.dart';

class ApplicationsRepository {
  const ApplicationsRepository();

  /// Applications the signed-in purohit has submitted.
  Future<List<Application>> mine() async {
    final uid = currentUserId;
    if (uid == null) return const [];

    final res = await supabase
        .from('applications')
        // The FK name is not decoration. Two paths exist between these tables
        // (applications.job_id -> jobs, and jobs.selected_application_id ->
        // applications), so an unqualified `jobs(title)` makes PostgREST throw
        // PGRST201 rather than guess. Any future reviews+jobs embed hits this
        // same trap.
        .select('id, job_id, pandit_id, message, quoted_fee, status, created_at, '
            'jobs!applications_job_id_fkey(title)')
        .eq('pandit_id', uid)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => Application.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Applications received on one of the family's own jobs.
  Future<List<Application>> forJob(int jobId) async {
    if (!supabaseReady) return const [];

    final res = await supabase
        .from('applications')
        .select('id, job_id, pandit_id, message, quoted_fee, status, created_at, '
            'pandit_profiles(experience_years, '
            'profiles(full_name, avatar_url))')
        .eq('job_id', jobId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => Application.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// True when this purohit already applied — the table has a
  /// `unique (job_id, pandit_id)` constraint, so a second insert is a 409.
  Future<bool> hasApplied(int jobId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final res = await supabase
        .from('applications')
        .select('id')
        .eq('job_id', jobId)
        .eq('pandit_id', uid)
        .maybeSingle();
    return res != null;
  }

  Future<void> apply({
    required int jobId,
    String? message,
    num? quotedFee,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Sign in to apply.');

    await supabase.from('applications').insert({
      'job_id': jobId,
      'pandit_id': uid,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      if (quotedFee != null) 'quoted_fee': quotedFee,
    });
  }

  /// The family picks one purohit and closes the job.
  ///
  /// Three writes, deliberately in this order:
  ///   1. every other applicant -> `rejected`
  ///   2. the chosen one        -> `selected`
  ///   3. the job               -> `assigned` + `selected_application_id`
  ///
  /// Step 2 is what opens `v_job_contacts`, so it must not run before the
  /// losers are cleared - two `selected` rows on one job would hand out two
  /// sets of contact details. There is no transaction across PostgREST calls;
  /// a failure between steps leaves the job open and is safe to retry.
  ///
  /// No new RLS was needed: `apps_update` already lets the job owner update
  /// applications on their own job, and `jobs_update` already lets them update
  /// the job.
  Future<void> finalize({
    required int applicationId,
    required int jobId,
  }) async {
    await supabase
        .from('applications')
        .update({'status': 'rejected'})
        .eq('job_id', jobId)
        .neq('id', applicationId);

    await supabase
        .from('applications')
        .update({'status': 'selected'})
        .eq('id', applicationId);

    await supabase.from('jobs').update({
      'status': 'assigned',
      'selected_application_id': applicationId,
    }).eq('id', jobId);
  }
}

final applicationsRepositoryProvider =
    Provider<ApplicationsRepository>((ref) => const ApplicationsRepository());

final myApplicationsProvider = FutureProvider<List<Application>>(
  (ref) => ref.watch(applicationsRepositoryProvider).mine(),
);

final jobApplicationsProvider = FutureProvider.family<List<Application>, int>(
  (ref, jobId) => ref.watch(applicationsRepositoryProvider).forJob(jobId),
);

final hasAppliedProvider = FutureProvider.family<bool, int>(
  (ref, jobId) => ref.watch(applicationsRepositoryProvider).hasApplied(jobId),
);
