import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/supabase_providers.dart';
import '../../data/portfolio_repository.dart';
import '../../data/profile_repository.dart';
import '../../data/storage_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/user_avatar.dart';

/// Tappable avatar. Uploads to the public `profile-media` bucket and writes the
/// resulting URL onto `profiles.avatar_url`, which is what every other surface
/// (applicant tiles, chat, viewer profile) reads.
class AvatarEditor extends ConsumerStatefulWidget {
  const AvatarEditor({super.key, required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  ConsumerState<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends ConsumerState<AvatarEditor> {
  bool _busy = false;

  Future<void> _change() async {
    final uid = currentUserId;
    if (_busy || uid == null) return;
    try {
      final picked = await pickCompressedImage(context);
      if (picked == null) return;
      setState(() => _busy = true);

      final storage = ref.read(storageRepositoryProvider);
      final path = profileMediaObjectPath(
        uid: uid,
        slot: 'avatar',
        extension: picked.extension,
      );
      await storage.upload(
        bucket: kProfileMediaBucket,
        path: path,
        bytes: picked.bytes,
        contentType: picked.contentType,
      );
      final url = storage.publicUrl(bucket: kProfileMediaBucket, path: path);
      await ref.read(profileRepositoryProvider).setAvatarUrl(url);
      await ref.read(sessionProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _change,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(
            name: widget.name,
            imageUrl: widget.avatarUrl,
            radius: 30,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.saffron,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera,
                      size: 12,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Work photos, owner view: add and remove. The read-only version families see
/// lives in `purohit_public_page.dart`.
class PortfolioEditor extends ConsumerStatefulWidget {
  const PortfolioEditor({super.key, required this.panditId});

  final String panditId;

  @override
  ConsumerState<PortfolioEditor> createState() => _PortfolioEditorState();
}

class _PortfolioEditorState extends ConsumerState<PortfolioEditor> {
  bool _busy = false;

  Future<void> _add() async {
    final uid = currentUserId;
    if (_busy || uid == null) return;
    try {
      final picked = await pickCompressedImage(context);
      if (picked == null) return;
      setState(() => _busy = true);

      final path = profileMediaObjectPath(
        uid: uid,
        slot: 'work',
        extension: picked.extension,
      );
      await ref.read(storageRepositoryProvider).upload(
            bucket: kProfileMediaBucket,
            path: path,
            bytes: picked.bytes,
            contentType: picked.contentType,
          );
      await ref.read(portfolioRepositoryProvider).add(objectPath: path);
      ref.invalidate(portfolioProvider(widget.panditId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int id) async {
    try {
      await ref.read(portfolioRepositoryProvider).remove(id);
      ref.invalidate(portfolioProvider(widget.panditId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(portfolioProvider(widget.panditId));
    final storage = ref.watch(storageRepositoryProvider);

    return SizedBox(
      height: 120,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Could not load your photos.',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
        ),
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: Gap.sm),
          itemBuilder: (context, i) {
            if (i == 0) {
              return InkWell(
                onTap: _busy ? null : _add,
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.saffronTint,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Center(
                    child: _busy
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.saffronDark,
                              ),
                              SizedBox(height: Gap.xs),
                              Text(
                                'Add photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.saffronDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            }

            final item = items[i - 1];
            final url = storage.publicUrl(
              bucket: kProfileMediaBucket,
              path: item.objectPath,
            );
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  child: Container(
                    width: 120,
                    height: 120,
                    color: AppColors.saffronTint,
                    child: url == null
                        ? const Icon(Icons.image_outlined)
                        : Image.network(url, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _remove(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
