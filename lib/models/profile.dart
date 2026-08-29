/// Which side of the marketplace the signed-in user is on.
///
/// Originally derived purely from the existence of a `pandit_profiles` row.
/// That still gates the jobs feed, but registration now needs the answer
/// *before* any purohit row exists — a brand new purohit has picked their side
/// and must not be dropped into the family app while their listing is empty.
/// So `profiles.account_type` records the choice at signup and a database
/// trigger makes it permanent, which is what enforces one email, one role.
enum UserRole {
  family,
  purohit;

  String get label => this == UserRole.family ? 'Family' : 'Purohit';

  /// The value stored in `profiles.account_type` and sent as signup metadata.
  String get wire => this == UserRole.purohit ? 'purohit' : 'family';

  static UserRole parse(String? v) =>
      v == 'purohit' ? UserRole.purohit : UserRole.family;
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
    this.accountType = UserRole.family,
    this.phone,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final int? cityId;
  final String locale;

  /// Chosen at registration and immutable afterwards — `guard_account_type`
  /// raises if anything but an admin tries to change it. This is what stops an
  /// email registered as a family account from also becoming a purohit.
  final UserRole accountType;
  final String? phone;

  static Profile fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
        cityId: (m['city_id'] as num?)?.toInt(),
        locale: m['locale'] as String? ?? 'en',
        accountType: UserRole.parse(m['account_type'] as String?),
        phone: m['phone'] as String?,
      );
}

class PanditProfile {
  const PanditProfile({
    required this.id,
    required this.status,
    this.dob,
    this.bio,
    this.experienceYears,
    this.baseFee,
    this.serviceRadiusKm = 25,
    this.languages = const [],
    this.isAvailable = true,
  });

  final String id;
  final VerificationStatus status;

  /// Null for purohits who registered before migration 0007.
  final DateTime? dob;
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
        dob: m['dob'] == null ? null : DateTime.tryParse(m['dob'].toString()),
        bio: m['bio'] as String?,
        experienceYears: (m['experience_years'] as num?)?.toInt(),
        baseFee: m['base_fee'] == null ? null : num.tryParse(m['base_fee'].toString()),
        serviceRadiusKm: (m['service_radius_km'] as num?)?.toInt() ?? 25,
        languages:
            (m['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isAvailable: m['is_available'] as bool? ?? true,
      );
}
