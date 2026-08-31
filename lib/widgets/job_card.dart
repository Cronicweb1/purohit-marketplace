import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/l10n/enum_labels.dart';
import '../core/l10n/locale_controller.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import 'feedback.dart';

/// The Upwork job card, retuned for rituals.
///
/// Ordering is deliberate: title, then the two facts that decide whether a
/// purohit taps (money and date), then location, then a two-line teaser.
/// Everything else is noise on a scroll surface.
class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.onTap, this.showStatus = false});

  final Job job;
  final VoidCallback? onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return PressScale(
      enabled: onTap != null,
      child: Card(
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (job.urgency == JobUrgency.immediate)
                    _Pill(text: t.urgent, color: AppColors.maroon),
                  if (showStatus && job.status != JobStatus.open) ...[
                    const SizedBox(width: Gap.xs),
                    _Pill(text: job.status.labelIn(t), color: AppColors.inkMuted),
                  ],
                ],
              ),
              const SizedBox(height: Gap.xs),
              Text(
                t.postedAgo(timeAgo(job.createdAt, t)),
                style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
              ),
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  _Fact(
                    icon: Icons.currency_rupee,
                    label: formatBudget(job.budget, t),
                    strong: true,
                  ),
                  const SizedBox(width: Gap.lg),
                  _Fact(
                    icon: Icons.event,
                    label: formatDateRange(job.startDate, job.endDate),
                  ),
                ],
              ),
              if (job.locationLabel != null) ...[
                const SizedBox(height: Gap.sm),
                _Fact(icon: Icons.place_outlined, label: job.locationLabel!),
              ],
              if ((job.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: Gap.md),
                Text(
                  job.description!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
              if (job.ritualName != null) ...[
                const SizedBox(height: Gap.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.md,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.saffronTint,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      job.ritualName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.saffronDark,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.strong = false});

  final IconData icon;
  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkMuted),
          const SizedBox(width: Gap.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: strong ? AppColors.ink : AppColors.inkMuted,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
