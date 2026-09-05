import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/supabase_providers.dart';
import '../../data/messages_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../../widgets/user_avatar.dart';
import '../shell/home_shell.dart';

/// Inbox. Shown to both roles, which is why it is an unconditional shell
/// branch - a tab that appears for one role and not the other would shift every
/// other branch index underneath it.
class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos = ref.watch(conversationsProvider);
    final unread = ref.watch(unreadCountsProvider).value ?? const <int, int>{};
    final uid = currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
        leading: const ShellProfileButton(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(conversationsProvider);
          ref.invalidate(unreadCountsProvider);
          await ref.read(conversationsProvider.future);
        },
        child: convos.when(
          loading: () => const TileListSkeleton(),
          error: (e, _) => RefreshableBody(
            child: ErrorView(
              error: e,
              onRetry: () => ref.invalidate(conversationsProvider),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const RefreshableBody(
                child: EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No conversations yet',
                  message:
                      'A chat opens when a family reaches out to a purohit who '
                      'applied to their ceremony.',
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(Gap.lg),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: Gap.sm),
              itemBuilder: (context, i) {
                final c = list[i];
                final count = unread[c.id] ?? 0;

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Gap.md,
                      vertical: Gap.xs,
                    ),
                    leading: UserAvatar(
                      name: c.counterpartName(uid),
                      imageUrl: c.counterpartAvatarUrl(uid),
                    ),
                    title: Text(
                      c.counterpartName(uid),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: count == 1
                        ? Consumer(
                            builder: (context, ref, _) {
                              final messages = ref.watch(
                                conversationMessagesProvider(c.id),
                              );
                              return messages.maybeWhen(
                                data: (items) {
                                  final unreadMessages = items.reversed
                                      .where((m) => !m.isMine(uid) && m.readAt == null)
                                      .toList();
                                  final preview = unreadMessages.isNotEmpty
                                      ? unreadMessages.first.body
                                      : (items.isNotEmpty ? items.last.body : null);
                                  return Text(
                                    preview ?? c.jobTitle ?? 'Ceremony',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.inkMuted,
                                    ),
                                  );
                                },
                                orElse: () => Text(
                                  c.jobTitle ?? 'Ceremony',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              );
                            },
                          )
                        : Text(
                            c.jobTitle ?? 'Ceremony',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.inkMuted),
                          ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeAgo(c.lastMessageAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkFaint,
                          ),
                        ),
                        if (count > 1) ...[
                          const SizedBox(height: Gap.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.maroon,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => context.push('/messages/${c.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
