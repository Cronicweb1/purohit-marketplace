import '../../models/application.dart';
import '../../models/job.dart';
import 'app_strings.dart';

/// Localized labels for the model enums.
///
/// The enums keep their English `.label` getters (handy in logs and in
/// anything that is not user-facing); these extensions provide the
/// translated variant so that `AppStrings` never has to import models.
extension JobUrgencyL10n on JobUrgency {
  String labelIn(AppStrings t) => switch (this) {
        JobUrgency.flexible => t.urgencyFlexible,
        JobUrgency.scheduled => t.urgencyScheduled,
        JobUrgency.immediate => t.urgencyImmediate,
      };
}

extension JobStatusL10n on JobStatus {
  String labelIn(AppStrings t) => switch (this) {
        JobStatus.open => t.jobStatusOpen,
        JobStatus.assigned => t.jobStatusAssigned,
        JobStatus.completed => t.jobStatusCompleted,
        JobStatus.cancelled => t.jobStatusCancelled,
      };
}

extension ApplicationStatusL10n on ApplicationStatus {
  String labelIn(AppStrings t) => switch (this) {
        ApplicationStatus.applied => t.appStatusApplied,
        ApplicationStatus.shortlisted => t.appStatusShortlisted,
        ApplicationStatus.selected => t.appStatusSelected,
        ApplicationStatus.rejected => t.appStatusRejected,
        ApplicationStatus.withdrawn => t.appStatusWithdrawn,
      };
}
