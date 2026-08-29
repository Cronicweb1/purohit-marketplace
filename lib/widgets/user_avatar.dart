import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/app_theme.dart';

/// One avatar rule for the whole app.
///
/// `foregroundImage` is used rather than `backgroundImage` so the initials stay
/// behind the photo: if the network fetch fails - offline, deleted object,
/// stale URL - the letters show through instead of a grey hole.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.saffron.withValues(alpha: 0.16),
      foregroundImage: hasImage ? NetworkImage(url) : null,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: AppColors.maroon,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}
