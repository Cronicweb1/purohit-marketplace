/// Identity and address documents a purohit submits for verification.
///
/// The `code` strings below are load-bearing: they are checked verbatim by the
/// `kyc_doc_type` and `kyc_type_matches_role` CHECK constraints in migration
/// 0006. Renaming one here without renaming it there produces a 23514 that
/// surfaces to the purohit as an unexplained "failed" at the end of a long form.
enum KycRole { identity, address }

extension KycRoleX on KycRole {
  String get code => this == KycRole.identity ? 'identity' : 'address';
  String get label =>
      this == KycRole.identity ? 'ID card' : 'Address proof';

  static KycRole fromCode(String code) =>
      code == 'address' ? KycRole.address : KycRole.identity;
}

class KycDocType {
  const KycDocType(this.code, this.label);

  final String code;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is KycDocType && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => label;
}

class KycDocTypes {
  const KycDocTypes._();

  /// Anything that proves who you are.
  static const List<KycDocType> identity = [
    KycDocType('aadhaar', 'Aadhaar card'),
    KycDocType('voter_id', 'Voter ID (EPIC)'),
    KycDocType('pan', 'PAN card'),
    KycDocType('driving_licence', 'Driving licence'),
    KycDocType('passport', 'Passport'),
    KycDocType('ration_card', 'Ration card'),
  ];

  /// Anything that proves where you live. A PAN card carries no address, and a
  /// passport or licence address is usually years stale, so neither is offered
  /// here - that asymmetry is enforced in the database too.
  static const List<KycDocType> address = [
    KycDocType('aadhaar', 'Aadhaar card'),
    KycDocType('voter_id', 'Voter ID (EPIC)'),
    KycDocType('ration_card', 'Ration card'),
    KycDocType('electricity_bill', 'Electricity bill'),
    KycDocType('lpg_bill', 'LPG gas bill'),
  ];

  static List<KycDocType> forRole(KycRole role) =>
      role == KycRole.identity ? identity : address;

  static String labelOf(String code) {
    for (final t in identity) {
      if (t.code == code) return t.label;
    }
    for (final t in address) {
      if (t.code == code) return t.label;
    }
    return code;
  }
}

/// One stored document. `storagePath` is an object key, never a URL: the bucket
/// is private, so a viewable link has to be signed at read time.
class KycDocument {
  const KycDocument({
    required this.id,
    required this.role,
    required this.docType,
    required this.storageProvider,
    required this.storagePath,
    this.mimeType,
    this.sizeBytes,
    this.createdAt,
  });

  final int id;
  final KycRole role;
  final String docType;
  final String storageProvider;
  final String storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime? createdAt;

  bool get isIdentity => role == KycRole.identity;
  String get typeLabel => KycDocTypes.labelOf(docType);
  String get roleLabel => role.label;

  String get readableSize {
    final b = sizeBytes;
    if (b == null) return '';
    final kb = b / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  static KycDocument fromMap(Map<String, dynamic> m) => KycDocument(
        id: (m['id'] as num).toInt(),
        role: KycRoleX.fromCode((m['doc_role'] ?? 'identity') as String),
        docType: (m['doc_type'] ?? '') as String,
        storageProvider: (m['storage_provider'] ?? 'supabase') as String,
        storagePath: (m['storage_path'] ?? '') as String,
        mimeType: m['mime_type'] as String?,
        sizeBytes: (m['size_bytes'] as num?)?.toInt(),
        createdAt: m['created_at'] == null
            ? null
            : DateTime.tryParse(m['created_at'] as String),
      );
}
