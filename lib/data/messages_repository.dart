import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/conversation.dart';

/// Direct messages between a family and a purohit who applied to their job.
///
/// Reads are plain PostgREST, not Realtime. The conversation screen polls, and
/// the inbox refreshes on pull. That is a deliberate first cut: Realtime adds a
/// websocket lifecycle to get wrong, and threads here move at human speed.
class MessagesRepository {
  const MessagesRepository();

  static const _conversationSelect =
      'id, job_id, client_id, pandit_id, created_at, last_message_at, '
      'jobs(title), '
      // Two FKs land on `profiles` from this table, so both embeds must name
      // the constraint or PostgREST returns PGRST201 instead of guessing.
      'client:profiles!conversations_client_id_fkey(full_name, avatar_url), '
      'pandit:profiles!conversations_pandit_id_fkey(full_name, avatar_url)';

  /// Every thread the signed-in user is part of, newest activity first.
  /// RLS already restricts rows to the two participants.
  Future<List<Conversation>> conversations() async {
    if (!supabaseReady || currentUserId == null) return const [];

    final res = await supabase
        .from('conversations')
        .select(_conversationSelect)
        .order('last_message_at', ascending: false);
    return (res as List)
        .map((e) => Conversation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Conversation?> byId(int id) async {
    if (!supabaseReady) return null;

    final res = await supabase
        .from('conversations')
        .select(_conversationSelect)
        .eq('id', id)
        .maybeSingle();
    return res == null
        ? null
        : Conversation.fromMap(Map<String, dynamic>.from(res));
  }

  /// Returns the thread id for this (job, purohit) pair, creating it if the
  /// family has not messaged this applicant before.
  ///
  /// Only the family can create one - `conv_insert` enforces that server-side,
  /// so a purohit calling this on a thread that does not exist gets a 403
  /// rather than a silent no-op.
  Future<int> openOrCreate({
    required int jobId,
    required String panditId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Sign in to send a message.');

    final existing = await supabase
        .from('conversations')
        .select('id')
        .eq('job_id', jobId)
        .eq('pandit_id', panditId)
        .maybeSingle();
    if (existing != null) return (existing['id'] as num).toInt();

    final created = await supabase
        .from('conversations')
        .insert({'job_id': jobId, 'client_id': uid, 'pandit_id': panditId})
        .select('id')
        .single();
    return (created['id'] as num).toInt();
  }

  Future<List<Message>> messages(int conversationId) async {
    if (!supabaseReady) return const [];

    final res = await supabase
        .from('messages')
        .select('id, conversation_id, sender_id, body, created_at, read_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (res as List)
        .map((e) => Message.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> send({required int conversationId, required String body}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Sign in to send a message.');
    final text = body.trim();
    if (text.isEmpty) return;

    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': text,
    });
  }

  /// Stamps everything the other side sent as read. Best effort - a failure
  /// here must never block the thread from rendering.
  Future<void> markRead(int conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await supabase
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', uid)
          .isFilter('read_at', null);
    } catch (_) {
      // Ignored on purpose.
    }
  }

  /// Unread count per conversation, for the inbox badges. Counted client-side
  /// because PostgREST cannot group without an RPC, and the row set is bounded
  /// by "messages this user has not opened yet".
  Future<Map<int, int>> unreadCounts() async {
    final uid = currentUserId;
    if (uid == null) return const {};

    try {
      final res = await supabase
          .from('messages')
          .select('conversation_id')
          .neq('sender_id', uid)
          .isFilter('read_at', null);
      final counts = <int, int>{};
      for (final row in res as List) {
        final id = ((row as Map)['conversation_id'] as num).toInt();
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      return const {};
    }
  }
}

final messagesRepositoryProvider =
    Provider<MessagesRepository>((ref) => const MessagesRepository());

final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(messagesRepositoryProvider).conversations(),
);

final conversationProvider = FutureProvider.family<Conversation?, int>(
  (ref, id) => ref.watch(messagesRepositoryProvider).byId(id),
);

final conversationMessagesProvider = FutureProvider.family<List<Message>, int>(
  (ref, id) => ref.watch(messagesRepositoryProvider).messages(id),
);

final unreadCountsProvider = FutureProvider<Map<int, int>>(
  (ref) => ref.watch(messagesRepositoryProvider).unreadCounts(),
);
