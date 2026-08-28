import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/profile.dart';

class ProfileRepository {
  const ProfileRepository();

  /// Creates the `profiles` row, and — when the user picks the purohit side —
  /// the `pandit_profiles` row too.
  ///
  /// `status` is NOT passed. A `guard_pandit_status()` trigger rejects any
  /// client-supplied value; every purohit starts at `pending` and an admin
  /// moves them to `approved`.
  Future<void> completeOnboarding({
    required String fullName,
    required UserRole role,
    int? cityId,
    String? bio,
    int? experienceYears,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Not signed in.');

    await supabase.from('profiles').upsert({
      'id': uid,
      'full_name': fullName.trim(),
      if (cityId != null) 'city_id': cityId,
    });

    if (role == UserRole.purohit) {
      await supabase.from('pandit_profiles').upsert({
        'id': uid,
        if (cityId != null) 'city_id': cityId,
        if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
        if (experienceYears != null) 'experience_years': experienceYears,
      });
    }
  }

  /// Publicly listed purohits. Anon-readable, but only rows where
  /// `status = 'approved'` come back — `pandit_public_read` enforces it.
  Future<List<Map<String, dynamic>>> approvedPandits({int? cityId}) async {
    if (!supabaseReady) return const [];

    var q = supabase
        .from('pandit_profiles')
        .select('id, bio, experience_years, base_fee, languages, is_available, '
            'profiles(full_name, avatar_url), cities(name, state)')
        .eq('status', 'approved');

    if (cityId != null) q = q.eq('city_id', cityId);

    final res = await q.order('experience_years', ascending: false).limit(50);
    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => const ProfileRepository());

final approvedPanditsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(profileRepositoryProvider).approvedPandits(),
);
