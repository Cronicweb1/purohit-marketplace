enum JobUrgency {
  flexible,
  scheduled,
  immediate;

  static JobUrgency parse(String? v) => switch (v) {
        'flexible' => JobUrgency.flexible,
        'immediate' => JobUrgency.immediate,
        _ => JobUrgency.scheduled,
      };

  String get label => switch (this) {
        JobUrgency.flexible => 'Flexible date',
        JobUrgency.scheduled => 'Scheduled',
        JobUrgency.immediate => 'Immediate',
      };
}

enum JobStatus {
  open,
  assigned,
  completed,
  cancelled;

  static JobStatus parse(String? v) => switch (v) {
        'assigned' => JobStatus.assigned,
        'completed' => JobStatus.completed,
        'cancelled' => JobStatus.cancelled,
        _ => JobStatus.open,
      };

  String get label => switch (this) {
        JobStatus.open => 'Open',
        JobStatus.assigned => 'Purohit selected',
        JobStatus.completed => 'Completed',
        JobStatus.cancelled => 'Cancelled',
      };
}

/// A request posted by a family. The purohit-facing feed is a list of these.
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.startDate,
    required this.createdAt,
    required this.urgency,
    required this.status,
    this.description,
    this.endDate,
    this.budget,
    this.ritualName,
    this.cityName,
    this.cityState,
    this.applicationCount = 0,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final JobUrgency urgency;
  final JobStatus status;
  final num? budget;
  final String? ritualName;
  final String? cityName;
  final String? cityState;
  final int applicationCount;

  String? get locationLabel {
    if (cityName == null) return null;
    return cityState == null ? cityName : '$cityName, $cityState';
  }

  /// Rows come from a select with embedded `rituals(name)` and `cities(name,
  /// state)`. PostgREST returns those as nested maps, or null when the FK is
  /// null — hence the defensive reads rather than a blind cast.
  static Job fromMap(Map<String, dynamic> m) {
    final ritual = m['rituals'];
    final city = m['cities'];
    final apps = m['applications'];

    return Job(
      id: (m['id'] as num).toInt(),
      title: m['title'] as String,
      description: m['description'] as String?,
      startDate: DateTime.parse(m['start_date'] as String),
      endDate: m['end_date'] == null ? null : DateTime.parse(m['end_date'] as String),
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      urgency: JobUrgency.parse(m['urgency'] as String?),
      status: JobStatus.parse(m['status'] as String?),
      budget: m['budget'] == null ? null : num.tryParse(m['budget'].toString()),
      ritualName: ritual is Map ? ritual['name'] as String? : null,
      cityName: city is Map ? city['name'] as String? : null,
      cityState: city is Map ? city['state'] as String? : null,
      applicationCount: apps is List && apps.isNotEmpty && apps.first is Map
          ? ((apps.first as Map)['count'] as num?)?.toInt() ?? 0
          : 0,
    );
  }
}
