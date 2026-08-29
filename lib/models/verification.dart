import 'kyc_document.dart';

/// Proof-of-training records shown to an admin during verification.
///
/// Two independent paths exist on purpose: many practising purohits never
/// attended a formal Gurukul, so a documented guru reference has to carry the
/// same weight as a certificate. `certificates` and `guru_references` are both
/// owner-or-admin only under RLS — they are never public.
class Certificate {
  const Certificate({
    required this.id,
    required this.kind,
    required this.institution,
    this.issuedOn,
    this.storageProvider = 'supabase',
    this.storagePath = '',
  });

  final int id;
  final String kind;
  final String institution;
  final DateTime? issuedOn;
  final String storageProvider;
  final String storagePath;

  bool get hasDocument =>
      storagePath.isNotEmpty && storagePath != 'pending-upload';

  /// True when the scan lives in our own private bucket rather than being a
  /// link to somebody else's Drive.
  bool get isStoredObject =>
      storageProvider == 'supabase' && hasDocument;

  /// The row only ever stores a path/URL, never the file itself.
  String? get documentUrl =>
      storageProvider == 'external_link' && hasDocument ? storagePath : null;

  static Certificate fromMap(Map<String, dynamic> m) => Certificate(
        id: (m['id'] as num).toInt(),
        kind: m['kind'] as String? ?? 'gurukul',
        institution: m['institution'] as String? ?? '',
        issuedOn: m['issued_on'] == null
            ? null
            : DateTime.tryParse(m['issued_on'].toString()),
        storageProvider: m['storage_provider'] as String? ?? 'supabase',
        storagePath: m['storage_path'] as String? ?? '',
      );
}

class GuruReference {
  const GuruReference({
    required this.id,
    required this.guruName,
    required this.guruPhone,
    this.gurukulName,
    this.yearsStudied,
    this.notes,
  });

  final int id;
  final String guruName;
  /// Non-nullable since `0005_guru_phone_required.sql`: an unreachable guru is
  /// an unverifiable reference. Rows that predate the migration were backfilled
  /// with the `not-provided` sentinel rather than deleted — they are a real
  /// purohit's only proof of training — so read through [hasPhone], never
  /// [guruPhone] directly.
  final String guruPhone;

  static const notProvided = 'not-provided';

  bool get hasPhone => guruPhone.isNotEmpty && guruPhone != notProvided;
  final String? gurukulName;
  final int? yearsStudied;
  final String? notes;

  static GuruReference fromMap(Map<String, dynamic> m) => GuruReference(
        id: (m['id'] as num).toInt(),
        guruName: m['guru_name'] as String? ?? '',
        guruPhone: m['guru_phone'] as String? ?? '',
        gurukulName: m['gurukul_name'] as String?,
        yearsStudied: (m['years_studied'] as num?)?.toInt(),
        notes: m['notes'] as String?,
      );
}

/// One row of the admin verification queue: the purohit plus everything an
/// admin needs to decide, fetched in a single embedded select.
class VerificationCase {
  const VerificationCase({
    required this.panditId,
    required this.fullName,
    required this.status,
    this.cityLabel,
    this.experienceYears,
    this.bio,
    this.languages = const [],
    this.certificates = const [],
    this.guruReferences = const [],
    this.kycDocuments = const [],
    this.submittedAt,
  });

  final String panditId;
  final String fullName;

  /// Raw enum text from Postgres: pending | under_review | approved | rejected.
  final String status;
  final String? cityLabel;
  final int? experienceYears;
  final String? bio;
  final List<String> languages;
  final List<Certificate> certificates;
  final List<GuruReference> guruReferences;
  final List<KycDocument> kycDocuments;
  final DateTime? submittedAt;

  /// An admin should never approve someone with neither proof on file.
  bool get hasProof => certificates.isNotEmpty || guruReferences.isNotEmpty;

  KycDocument? get identityDocument {
    for (final d in kycDocuments) {
      if (d.isIdentity) return d;
    }
    return null;
  }

  KycDocument? get addressDocument {
    for (final d in kycDocuments) {
      if (!d.isIdentity) return d;
    }
    return null;
  }

  /// Training proof says someone can perform the ceremony. This says we know
  /// who they are - a separate question, and the one a family cares about.
  bool get hasIdentityDocument => identityDocument != null;

  static VerificationCase fromMap(Map<String, dynamic> m) {
    final profile = m['profiles'] as Map<String, dynamic>?;
    final city = m['cities'] as Map<String, dynamic>?;
    return VerificationCase(
      panditId: m['id'].toString(),
      fullName: profile?['full_name'] as String? ?? 'Unnamed purohit',
      status: m['status'] as String? ?? 'pending',
      cityLabel: city == null ? null : '${city['name']}, ${city['state']}',
      experienceYears: (m['experience_years'] as num?)?.toInt(),
      bio: m['bio'] as String?,
      languages:
          (m['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      certificates: ((m['certificates'] as List?) ?? const [])
          .map((e) => Certificate.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      guruReferences: ((m['guru_references'] as List?) ?? const [])
          .map((e) => GuruReference.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      kycDocuments: ((m['kyc_documents'] as List?) ?? const [])
          .map((e) => KycDocument.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      submittedAt: m['created_at'] == null
          ? null
          : DateTime.tryParse(m['created_at'].toString()),
    );
  }
}
