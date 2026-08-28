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
        .select('id, job_id, pandit_id, message, quoted_fee, status, created_at, '
            'jobs(title)')
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
            'pandit_profiles(experience_years, profiles(full_name))')
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
