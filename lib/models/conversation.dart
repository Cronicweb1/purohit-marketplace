/// One thread between the family that posted a job and a purohit who applied
/// to it. Unique on `(job_id, pandit_id)` in the database.
///
/// Contact details are deliberately absent here for the same reason they are
/// absent from `Application`: phone and e-mail come only from `v_job_contacts`,
/// and only once the application is `selected`. Chatting early is fine;
/// exchanging numbers early is not.
class Conversation {
  const Conversation({
    required this.id,
    required this.jobId,
    required this.clientId,
    required this.panditId,
    required this.lastMessageAt,
    this.jobTitle,
    this.clientName,
    this.clientAvatarUrl,
    this.panditName,
    this.panditAvatarUrl,
  });

  final int id;
  final int jobId;
  final String clientId;
  final String panditId;
  final DateTime lastMessageAt;
  final String? jobTitle;
  final String? clientName;
  final String? clientAvatarUrl;
  final String? panditName;
  final String? panditAvatarUrl;

  bool viewerIsClient(String? uid) => uid != null && uid == clientId;

  /// The other person, whichever side the viewer is on. One inbox screen
  /// serves both roles because of this.
  String counterpartName(String? uid) =>
      (viewerIsClient(uid) ? panditName : clientName) ?? 'Member';

  String? counterpartAvatarUrl(String? uid) =>
      viewerIsClient(uid) ? panditAvatarUrl : clientAvatarUrl;

  static Conversation fromMap(Map<String, dynamic> m) {
    final job = m['jobs'];
    final client = m['client'];
    final pandit = m['pandit'];

    return Conversation(
      id: (m['id'] as num).toInt(),
      jobId: (m['job_id'] as num).toInt(),
      clientId: m['client_id'] as String,
      panditId: m['pandit_id'] as String,
      lastMessageAt:
          DateTime.parse((m['last_message_at'] ?? m['created_at']) as String)
              .toLocal(),
      jobTitle: job is Map ? job['title'] as String? : null,
      clientName: client is Map ? client['full_name'] as String? : null,
      clientAvatarUrl: client is Map ? client['avatar_url'] as String? : null,
      panditName: pandit is Map ? pandit['full_name'] as String? : null,
      panditAvatarUrl: pandit is Map ? pandit['avatar_url'] as String? : null,
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final int conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool isMine(String? uid) => uid != null && uid == senderId;

  static Message fromMap(Map<String, dynamic> m) => Message(
        id: (m['id'] as num).toInt(),
        conversationId: (m['conversation_id'] as num).toInt(),
        senderId: m['sender_id'] as String,
        body: m['body'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        readAt: m['read_at'] == null
            ? null
            : DateTime.parse(m['read_at'] as String).toLocal(),
      );
}
