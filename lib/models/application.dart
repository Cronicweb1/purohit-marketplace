enum ApplicationStatus {
  applied,
  shortlisted,
  selected,
  rejected,
  withdrawn;

  static ApplicationStatus parse(String? v) => switch (v) {
        'shortlisted' => ApplicationStatus.shortlisted,
        'selected' => ApplicationStatus.selected,
        'rejected' => ApplicationStatus.rejected,
        'withdrawn' => ApplicationStatus.withdrawn,
        _ => ApplicationStatus.applied,
      };

  String get label => switch (this) {
        ApplicationStatus.applied => 'Applied',
        ApplicationStatus.shortlisted => 'Shortlisted',
        ApplicationStatus.selected => 'Selected',
        ApplicationStatus.rejected => 'Not selected',
        ApplicationStatus.withdrawn => 'Withdrawn',
      };
}

/// A purohit's bid on a job.
///
/// Contact details are NOT on this object. They are exposed only through the
/// `v_job_contacts` view, and only once `status = 'selected'` — that gate is the
/// commission model, so never widen this class to carry a phone number.
class Application {
  const Application({
    required this.id,
    required this.jobId,
    required this.panditId,
    required this.status,
    required this.createdAt,
    this.message,
    this.quotedFee,
    this.panditName,
    this.panditExperienceYears,
    this.jobTitle,
  });

  final int id;
  final int jobId;
  final String panditId;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String? message;
  final num? quotedFee;
  final String? panditName;
  final int? panditExperienceYears;
  final String? jobTitle;

  static Application fromMap(Map<String, dynamic> m) {
    final pandit = m['pandit_profiles'];
    final profile = pandit is Map ? pandit['profiles'] : null;
    final job = m['jobs'];

    return Application(
      id: (m['id'] as num).toInt(),
      jobId: (m['job_id'] as num).toInt(),
      panditId: m['pandit_id'] as String,
      status: ApplicationStatus.parse(m['status'] as String?),
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      message: m['message'] as String?,
      quotedFee:
          m['quoted_fee'] == null ? null : num.tryParse(m['quoted_fee'].toString()),
      panditName: profile is Map ? profile['full_name'] as String? : null,
      panditExperienceYears:
          pandit is Map ? (pandit['experience_years'] as num?)?.toInt() : null,
      jobTitle: job is Map ? job['title'] as String? : null,
    );
  }
}
