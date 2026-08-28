/// Which side of the marketplace the signed-in user is on.
///
/// Deliberately NOT a `profiles.role` column. The source of truth is whether a
/// `pandit_profiles` row exists for this user — which is exactly what the
/// `jobs_read` RLS policy checks, so the UI and the database can never disagree.
enum UserRole {
  family,
  purohit;

  String get label => this == UserRole.family ? 'Family' : 'Purohit';
}

/// Mirrors `verification_status`. Only `approved` purohits are publicly listed
/// and only they can see the open-jobs feed.
enum VerificationStatus {
  pending,
  underReview,
  approved,
  rejected;

  static VerificationStatus parse(String? v) => switch (v) {
        'under_review' => VerificationStatus.underReview,
        'approved' => VerificationStatus.approved,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.pending,
      };

  String get label => switch (this) {
        VerificationStatus.pending => 'Verification pending',
        VerificationStatus.underReview => 'Under review',
        VerificationStatus.approved => 'Verified',
        VerificationStatus.rejected => 'Verification rejected',
      };
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.cityId,
    this.locale = 'en',
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final int? cityId;
  final String locale;

  static Profile fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
        cityId: (m['city_id'] as num?)?.toInt(),
        locale: m['locale'] as String? ?? 'en',
      );
}

class PanditProfile {
  const PanditProfile({
    required this.id,
    required this.status,
    this.bio,
    this.experienceYears,
    this.baseFee,
    this.serviceRadiusKm = 25,
    this.languages = const [],
    this.isAvailable = true,
  });

  final String id;
  final VerificationStatus status;
  final String? bio;
  final int? experienceYears;
  final num? baseFee;
  final int serviceRadiusKm;
  final List<String> languages;
  final bool isAvailable;

  bool get isApproved => status == VerificationStatus.approved;

  static PanditProfile fromMap(Map<String, dynamic> m) => PanditProfile(
        id: m['id'] as String,
        status: VerificationStatus.parse(m['status'] as String?),
        bio: m['bio'] as String?,
        experienceYears: (m['experience_years'] as num?)?.toInt(),
        baseFee: m['base_fee'] == null ? null : num.tryParse(m['base_fee'].toString()),
        serviceRadiusKm: (m['service_radius_km'] as num?)?.toInt() ?? 25,
        languages:
            (m['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isAvailable: m['is_available'] as bool? ?? true,
      );
}
