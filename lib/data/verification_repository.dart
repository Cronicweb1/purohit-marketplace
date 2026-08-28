import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/verification.dart';

/// Everything the purohit-registration flow and the admin verification queue
/// need.
///
/// Two hard rules are encoded here, both enforced in the database as well:
///   1. `pandit_profiles.status` is NEVER written by a purohit. The
///      `guard_pandit_status()` trigger raises if a non-admin changes it, so
///      the client simply omits the column.
///   2. `verification_events` is admin-insert-only (`ve_insert` RLS policy), so
///      only [decide] writes to it. A purohit submitting proof does not, and
///      must not, log an event.
class VerificationRepository {
  const VerificationRepository();

  static const _caseColumns =
      'id, status, bio, experience_years, base_fee, service_radius_km, '
      'languages, is_available, created_at, '
      'profiles(full_name, avatar_url), '
      'cities(name, state), '
      'certificates(id, kind, institution, issued_on, storage_provider, storage_path), '
      'guru_references(id, guru_name, guru_phone, gurukul_name, years_studied, notes)';

  // ------------------------------------------------------------- purohit side

  /// Creates or updates the caller's `pandit_profiles` row.
  ///
  /// The existence of this row is what flips the app into purohit mode and what
  /// the `jobs_read` policy tests — so this single upsert IS the registration.
  Future<void> registerAsPurohit({
    required String fullName,
    int? cityId,
    String? bio,
    int? experienceYears,
    int? serviceRadiusKm,
    double? baseFee,
    List<String> languages = const [],
  }) async {
    if (!supabaseReady) return;
    final uid = currentUserId;
    if (uid == null) throw StateError('Not signed in.');

    await supabase.from('profiles').upsert({
      'id': uid,
      'full_name': fullName.trim(),
      if (cityId != null) 'city_id': cityId,
    });

    await supabase.from('pandit_profiles').upsert({
      'id': uid,
      if (cityId != null) 'city_id': cityId,
      if ((bio ?? '').trim().isNotEmpty) 'bio': bio!.trim(),
      if (experienceYears != null) 'experience_years': experienceYears,
      if (serviceRadiusKm != null) 'service_radius_km': serviceRadiusKm,
      if (baseFee != null) 'base_fee': baseFee,
      'languages': languages,
      // 'status' is deliberately absent. See the class doc.
    });
  }

  /// Replaces the purohit's specialisation list. Delete-then-insert keeps the
  /// `(pandit_id, ritual_id)` unique constraint happy without upsert gymnastics.
  Future<void> setSpecialisations(List<int> ritualIds) async {
    if (!supabaseReady) return;
    final uid = currentUserId;
    if (uid == null) throw StateError('Not signed in.');

    await supabase.from('pandit_rituals').delete().eq('pandit_id', uid);
    if (ritualIds.isEmpty) return;
    await supabase.from('pandit_rituals').insert([
      for (final id in ritualIds) {'pandit_id': uid, 'ritual_id': id},
    ]);
  }

  /// Path 1 of 2. `storage_path` is NOT NULL in the schema, so an unsupplied
  /// document is recorded honestly as a pending upload rather than a fake path.
  Future<void> addCertificate({
    required String institution,
    String kind = 'gurukul',
    DateTime? issuedOn,
    String? documentUrl,
  }) async {
    if (!supabaseReady) return;
    final uid = currentUserId;
    if (uid == null) throw StateError('Not signed in.');

    final url = (documentUrl ?? '').trim();
    await supabase.from('certificates').insert({
      'pandit_id': uid,
      'kind': kind,
      'institution': institution.trim(),
      if (issuedOn != null)
        'issued_on': issuedOn.toIso8601String().split('T').first,
      'storage_provider': url.isEmpty ? 'pending' : 'external_link',
      'storage_path': url.isEmpty ? 'pending-upload' : url,
    });
  }

  /// Path 2 of 2, for purohits trained outside a formal Gurukul.
  Future<void> addGuruReference({
    required String guruName,
    String? guruPhone,
    String? gurukulName,
    int? yearsStudied,
    String? notes,
  }) async {
    if (!supabaseReady) return;
    final uid = currentUserId;
    if (uid == null) throw StateError('Not signed in.');

    await supabase.from('guru_references').insert({
      'pandit_id': uid,
      'guru_name': guruName.trim(),
      if ((guruPhone ?? '').trim().isNotEmpty) 'guru_phone': guruPhone!.trim(),
      if ((gurukulName ?? '').trim().isNotEmpty)
        'gurukul_name': gurukulName!.trim(),
      if (yearsStudied != null) 'years_studied': yearsStudied,
      if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
    });
  }

  Future<List<Certificate>> myCertificates() async {
    if (!supabaseReady) return const [];
    final uid = currentUserId;
    if (uid == null) return const [];
    final res = await supabase
        .from('certificates')
        .select('id, kind, institution, issued_on, storage_provider, storage_path')
        .eq('pandit_id', uid)
        .order('created_at');
    return (res as List)
        .map((e) => Certificate.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<GuruReference>> myGuruReferences() async {
    if (!supabaseReady) return const [];
    final uid = currentUserId;
    if (uid == null) return const [];
    final res = await supabase
        .from('guru_references')
        .select('id, guru_name, guru_phone, gurukul_name, years_studied, notes')
        .eq('pandit_id', uid)
        .order('created_at');
    return (res as List)
        .map((e) => GuruReference.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // --------------------------------------------------------------- admin side

  /// The verification queue. Readable only because `pandit_public_read`,
  /// `certs_owner` and `guru_owner` all carry an `is_admin()` escape hatch —
  /// a non-admin calling this gets their own row back at most, never an error.
  Future<List<VerificationCase>> queue({String status = 'pending'}) async {
    if (!supabaseReady) return const [];
    final res = await supabase
        .from('pandit_profiles')
        .select(_caseColumns)
        .eq('status', status)
        .order('created_at')
        .limit(100);
    return (res as List)
        .map((e) => VerificationCase.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Moves a purohit through pending -> under_review -> approved | rejected and
  /// appends the transition to the immutable audit log. The status update runs
  /// first: if it is rejected by the trigger, no orphan event is written.
  Future<void> decide({
    required String panditId,
    required String fromStatus,
    required String toStatus,
    String? reason,
  }) async {
    if (!supabaseReady) return;

    await supabase
        .from('pandit_profiles')
        .update({'status': toStatus}).eq('id', panditId);

    await supabase.from('verification_events').insert({
      'pandit_id': panditId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'actor_id': currentUserId,
      if ((reason ?? '').trim().isNotEmpty) 'reason': reason!.trim(),
    });
  }
}

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) => const VerificationRepository());

/// Which bucket of the queue the admin screen is looking at.
final adminQueueFilterProvider = StateProvider<String>((ref) => 'pending');

final adminQueueProvider = FutureProvider<List<VerificationCase>>((ref) {
  final status = ref.watch(adminQueueFilterProvider);
  return ref.watch(verificationRepositoryProvider).queue(status: status);
});

final myCertificatesProvider = FutureProvider<List<Certificate>>(
  (ref) => ref.watch(verificationRepositoryProvider).myCertificates(),
);

final myGuruReferencesProvider = FutureProvider<List<GuruReference>>(
  (ref) => ref.watch(verificationRepositoryProvider).myGuruReferences(),
);
