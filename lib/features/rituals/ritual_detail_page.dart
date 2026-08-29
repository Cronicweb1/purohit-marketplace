import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../data/reference_repository.dart';
import '../../models/ritual.dart';
import '../../theme/app_theme.dart';
import 'ceremony_lore.dart';

/// Detail page for a single ceremony, reached from Browse at `/ceremony/:slug`.
///
/// It sits between browsing and posting: a family reads what the ceremony is
/// for, where it comes from and what actually happens on the day, and only then
/// taps through to the Post tab with the ritual already selected.
///
/// Readable while signed out, because Browse is.
class RitualDetailPage extends ConsumerWidget {
  const RitualDetailPage({required this.slug, super.key});

  /// The [Ritual.slug] taken from the route path.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rituals = ref.watch(ritualsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: rituals.when(
        loading: () => const _DetailSkeleton(),
        error: (_, __) => const _DetailMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load this ceremony',
          message: 'Check your connection and pull to try again.',
        ),
        data: (list) {
          Ritual? found;
          for (final r in list) {
            if (r.slug == slug) {
              found = r;
              break;
            }
          }
          if (found == null) {
            return const _DetailMessage(
              icon: Icons.search_off_rounded,
              title: 'Ceremony not found',
              message: 'This ceremony is no longer listed.',
            );
          }
          return _DetailBody(ritual: found);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.ritual});

  final Ritual ritual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lore = loreFor(ritual);
    final text = Theme.of(context).textTheme;
    var step = 0;
    int nextDelay() => 60 * step++;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _CeremonyHeader(ritual: ritual, lore: lore),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Reveal(
                    delayMs: nextDelay(),
                    child: _Section(
                      title: 'Why this ceremony is performed',
                      body: lore.why,
                    ),
                  ),
                  SizedBox(height: Gap.xl),
                  _Reveal(
                    delayMs: nextDelay(),
                    child: _QuoteCard(lore: lore),
                  ),
                  SizedBox(height: Gap.xl),
                  _Reveal(
                    delayMs: nextDelay(),
                    child: _Section(
                      title: 'Historical background',
                      body: lore.history,
                    ),
                  ),
                  if (lore.steps.isNotEmpty) ...[
                    SizedBox(height: Gap.xl),
                    _Reveal(
                      delayMs: nextDelay(),
                      child: _StepsBlock(steps: lore.steps),
                    ),
                  ],
                  if (lore.facts.isNotEmpty) ...[
                    SizedBox(height: Gap.xl),
                    _Reveal(
                      delayMs: nextDelay(),
                      child: _FactsBlock(facts: lore.facts),
                    ),
                  ],
                  SizedBox(height: Gap.xl),
                  _Reveal(
                    delayMs: nextDelay(),
                    child: Text(
                      'Customs vary between regions and families. Your purohit '
                      'will follow the tradition you keep at home.',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.inkFaint,
                        height: 1.5,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CeremonyCta(ritual: ritual),
        ),
      ],
    );
  }
}

/// Collapsing saffron header carrying the name, the Devanagari name and the
/// duration chips.
class _CeremonyHeader extends StatelessWidget {
  const _CeremonyHeader({required this.ritual, required this.lore});

  final Ritual ritual;
  final CeremonyLore lore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chips = <String>[
      if (ritual.isMultiDay)
        'Multi day'
      else if (ritual.typicalDurationMinutes != null)
        _durationLabel(ritual.typicalDurationMinutes!),
      if (!ritual.bookable) 'Speciality',
    ];

    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: AppColors.saffronDark,
      foregroundColor: Colors.white,
      title: Text(
        ritual.name,
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.saffron,
                AppColors.saffronDark,
                AppColors.maroon,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Gap.lg, Gap.xxl, Gap.lg, Gap.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ritual.nameHi != null)
                    Text(
                      ritual.nameHi!,
                      style: text.headlineSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(height: Gap.sm),
                  Text(
                    ritual.name,
                    style: text.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: Gap.sm),
                  Text(
                    lore.tagline,
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        for (final c in chips)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Gap.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              c,
                              style: text.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return h == 1 ? 'About 1 hour' : 'About $h hours';
    return 'About $h hr $m min';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.saffron,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                title,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Gap.md),
        Text(
          body,
          style: text.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.lore});

  final CeremonyLore lore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: AppColors.saffronTint,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: AppColors.saffron.withValues(alpha: 0.55),
            size: 28,
          ),
          SizedBox(height: Gap.sm),
          Text(
            lore.quote,
            style: text.titleMedium?.copyWith(
              color: AppColors.maroon,
              height: 1.75,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Gap.md),
          Text(
            lore.transliteration,
            style: text.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          SizedBox(height: Gap.md),
          Text(
            lore.meaning,
            style: text.bodyMedium?.copyWith(
              color: AppColors.ink,
              height: 1.55,
            ),
          ),
          SizedBox(height: Gap.md),
          Row(
            children: [
              Container(
                width: 18,
                height: 1,
                color: AppColors.saffron.withValues(alpha: 0.6),
              ),
              SizedBox(width: Gap.sm),
              Flexible(
                child: Text(
                  lore.source,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.saffronDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsBlock extends StatelessWidget {
  const _StepsBlock({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'What usually happens',
          body: 'The order below is typical. Your purohit will adjust it to '
              'your family tradition and the time available.',
        ),
        SizedBox(height: Gap.md),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: Gap.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.saffronTint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.saffronDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: Gap.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      steps[i],
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FactsBlock extends StatelessWidget {
  const _FactsBlock({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good to know',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: Gap.md),
          for (final f in facts)
            Padding(
              padding: EdgeInsets.only(bottom: Gap.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.marigold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      f,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sticky call to action. Families are sent to the Post tab with the ritual
/// already selected; signed out visitors are sent to sign in first.
class _CeremonyCta extends ConsumerWidget {
  const _CeremonyCta({required this.ritual});

  final Ritual ritual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final text = Theme.of(context).textTheme;
    final signedIn = session.status == SessionStatus.ready;
    final isPurohit = signedIn && session.isPurohit;

    String label;
    String? note;
    VoidCallback? onTap;

    if (!ritual.bookable) {
      note = 'This is a purohit speciality rather than a ceremony you book '
          'directly. Browse purohits who offer it.';
      label = 'Browse purohits';
      onTap = () => context.go('/browse');
    } else if (isPurohit) {
      note = 'You are signed in as a purohit. Families post this ceremony and '
          'you will see it in Discover.';
      label = 'Go to Discover';
      onTap = () => context.go('/jobs');
    } else if (signedIn) {
      label = 'Post this ceremony';
      onTap = () => context.go('/post?ritual=${ritual.id}');
    } else {
      note = 'Sign in to post this ceremony and receive quotes from verified '
          'purohits near you.';
      label = 'Sign in to continue';
      onTap = () => context.go('/sign-in');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.hairline)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note != null) ...[
                Text(
                  note,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: Gap.md),
              ],
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Gap.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child in once, after [delayMs].
///
/// Used to stagger the sections so the page assembles itself as you arrive
/// rather than snapping in all at once.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.08),
      duration: AppDuration.slow,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: AppDuration.slow,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.saffron),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(Gap.sm),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.ink,
                onPressed: () => context.go('/browse'),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(Gap.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 44, color: AppColors.inkFaint),
                  SizedBox(height: Gap.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: Gap.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
