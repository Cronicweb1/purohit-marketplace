import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/supabase_providers.dart';
import '../../data/messages_repository.dart';
import '../../models/conversation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/states.dart';
import '../../widgets/user_avatar.dart';

/// A single thread.
///
/// Refresh is a poll, not a realtime subscription. That is a deliberate first
/// cut: it needs no channel plumbing, no reconnect handling, and no extra RLS
/// surface, and an eight-second lag is invisible in a negotiation that happens
/// over hours. Swapping to `supabase.channel(...)` later touches only this
/// widget and the repository.
class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    await ref
        .read(messagesRepositoryProvider)
        .markRead(widget.conversationId);
    if (!mounted) return;
    ref.invalidate(unreadCountsProvider);
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(messagesRepositoryProvider).send(
            conversationId: widget.conversationId,
            body: body,
          );
      if (!mounted) return;
      _controller.clear();
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send. $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUserId;
    final convo = ref.watch(conversationProvider(widget.conversationId));
    final msgs =
        ref.watch(conversationMessagesProvider(widget.conversationId));

    final c = convo.value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/messages');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: c?.counterpartName(uid) ?? '',
              imageUrl: c?.counterpartAvatarUrl(uid),
              radius: 16,
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c?.counterpartName(uid) ?? 'Chat',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (c?.jobTitle != null)
                    Text(
                      c!.jobTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (c != null)
            IconButton(
              tooltip: 'Open ceremony',
              icon: const Icon(Icons.event_note_outlined),
              onPressed: () => context.push('/jobs/${c.jobId}'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(
                  conversationMessagesProvider(widget.conversationId),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Say hello',
                    message:
                        'Ask about the ritual, the samagri, or the timing '
                        'before you finalise anyone.',
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.all(Gap.lg),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[list.length - 1 - i];
                    return _Bubble(message: m, mine: m.isMine(uid));
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.saffron : AppColors.card,
          border: mine ? null : Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.card),
            topRight: const Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(mine ? AppRadius.card : Gap.xs),
            bottomRight: Radius.circular(mine ? Gap.xs : AppRadius.card),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(
                height: 1.35,
                color: mine ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeAgo(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.sm),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a message',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: Gap.sm),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
