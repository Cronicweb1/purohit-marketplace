import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _skeletonBase = Color(0xFFEDE7DF);
const _skeletonHigh = Color(0xFFF9F6F2);

/// Drives every [SkeletonBox] beneath it from a single ticker.
///
/// Upwork never shows a bare spinner on a list surface: it shows the shape of
/// the content that is about to arrive, so the page does not visually jump when
/// data lands. One controller feeds the whole subtree via an InheritedWidget,
/// so a screenful of placeholders costs one animation, not thirty.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(pulse: _pulse, child: widget.child);
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.pulse, required super.child});

  final Animation<double> pulse;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
        ?.pulse;
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      oldWidget.pulse != pulse;
}

/// A single grey placeholder rectangle. Pulses only if wrapped in a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final pulse = _ShimmerScope.maybeOf(context);
    final shape = BorderRadius.circular(radius);

    if (pulse == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: _skeletonBase, borderRadius: shape),
      );
    }

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Color.lerp(_skeletonBase, _skeletonHigh, pulse.value),
          borderRadius: shape,
        ),
      ),
    );
  }
}

/// A placeholder text line, sized as a fraction of the available width so it
/// reads as prose rather than as a bar chart.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 1, this.height = 12});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: SkeletonBox(height: height, radius: 6),
    );
  }
}

/// The silhouette of a [JobCard]: title, meta row, teaser, tag.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(widthFactor: 0.72, height: 15),
          SizedBox(height: Gap.sm),
          SkeletonLine(widthFactor: 0.3, height: 10),
          SizedBox(height: Gap.lg),
          Row(
            children: [
              SkeletonBox(width: 88, height: 12, radius: 6),
              SizedBox(width: Gap.lg),
              SkeletonBox(width: 104, height: 12, radius: 6),
            ],
          ),
          SizedBox(height: Gap.md),
          SkeletonLine(height: 11),
          SizedBox(height: Gap.sm),
          SkeletonLine(widthFactor: 0.85, height: 11),
          SizedBox(height: Gap.lg),
          SkeletonBox(width: 110, height: 26, radius: AppRadius.chip),
        ],
      ),
    );
  }
}

/// A scrollable screenful of job placeholders. Stays scrollable so a
/// pull-to-refresh gesture still works while the first page is loading.
class JobListSkeleton extends StatelessWidget {
  const JobListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
        itemBuilder: (_, __) => const JobCardSkeleton(),
      ),
    );
  }
}

/// One compact row: an avatar-sized square, two lines, a trailing stub.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 42, height: 42, radius: 10),
          SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(widthFactor: 0.55, height: 13),
                SizedBox(height: Gap.sm),
                SkeletonLine(widthFactor: 0.35, height: 10),
              ],
            ),
          ),
          SizedBox(width: Gap.md),
          SkeletonBox(width: 54, height: 22, radius: AppRadius.chip),
        ],
      ),
    );
  }
}

/// Shrink-wrapped stack of [SkeletonTile]s. Safe inside a sliver or a Column,
/// where a nested scroll view would have no bounded height.
class TileSkeletonColumn extends StatelessWidget {
  const TileSkeletonColumn({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: Gap.lg),
  });

  final int count;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: Gap.sm),
              const SkeletonTile(),
            ],
          ],
        ),
      ),
    );
  }
}

/// A scrollable screenful of compact rows.
class TileListSkeleton extends StatelessWidget {
  const TileListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
        itemBuilder: (_, __) => const SkeletonTile(),
      ),
    );
  }
}

/// Placeholder for a single detail page.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLine(widthFactor: 0.85, height: 20),
            SizedBox(height: Gap.md),
            SkeletonLine(widthFactor: 0.4, height: 12),
            SizedBox(height: Gap.xl),
            SkeletonBox(height: 92, radius: AppRadius.card),
            SizedBox(height: Gap.xl),
            SkeletonLine(height: 12),
            SizedBox(height: Gap.sm),
            SkeletonLine(height: 12),
            SizedBox(height: Gap.sm),
            SkeletonLine(widthFactor: 0.6, height: 12),
            SizedBox(height: Gap.xl),
            SkeletonBox(height: 50, radius: AppRadius.field),
          ],
        ),
      ),
    );
  }
}
