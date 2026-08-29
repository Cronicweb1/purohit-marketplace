import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// The public front door. Everything above the first tap has to explain the
/// marketplace to two very different audiences — a family that has never
/// booked a purohit online, and a purohit who has never taken work from an
/// app — so the page is one long scroll with a section for each.
///
/// All motion is hand-rolled on top of a single [ScrollController]. The app
/// deliberately ships no animation package, and a reveal-on-scroll effect is
/// only a position check plus an [AnimationController], so pulling in a
/// dependency for it would cost more than it saves.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();

  /// Drives the slow breathing halo behind the hero mark. Runs forever, which
  /// is fine: it is one 6s tween and it stops with the route.
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  /// The top bar only earns its space once the hero has scrolled away.
  bool _barVisible = false;

  static const _lines = [
    'Book a pandit the way you book anything else worth doing well.',
    'Every ritual deserves someone who knows why it is done.',
    'Muhurat, mantra, samagri — sorted before the guests arrive.',
    'Your family traditions, in hands that have held them before.',
  ];
  int _line = 0;
  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _lineTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _line = (_line + 1) % _lines.length);
    });
  }

  void _onScroll() {
    final shouldShow = _scroll.hasClients && _scroll.offset > 320;
    if (shouldShow != _barVisible) setState(() => _barVisible = shouldShow);
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width > 720;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                _Hero(scroll: _scroll, halo: _halo, line: _lines[_line]),
                _Reveal(
                  scroll: _scroll,
                  child: _WhatWeDo(wide: wide),
                ),
                _Reveal(
                  scroll: _scroll,
                  child: _HowItWorks(
                    eyebrow: 'For families',
                    title: 'Find the right purohit,\nnot just any purohit',
                    accent: AppColors.saffron,
                    tint: AppColors.saffronTint,
                    steps: const [
                      _Step(
                        icon: Icons.auto_stories_outlined,
                        title: 'Tell us the ritual',
                        body: 'Griha pravesh, satyanarayan katha, naamkaran, '
                            'shraddh — pick the ceremony and the date you have '
                            'in mind, along with your city.',
                      ),
                      _Step(
                        icon: Icons.group_outlined,
                        title: 'Compare verified purohits',
                        body: 'See experience, languages spoken, the traditions '
                            'they follow and what they charge. Every listed '
                            'purohit has cleared our verification.',
                      ),
                      _Step(
                        icon: Icons.chat_bubble_outline,
                        title: 'Talk, then confirm',
                        body: 'Message them about samagri, muhurat and how long '
                            'the puja runs. Confirm only once it feels right.',
                      ),
                    ],
                  ),
                ),
                _Reveal(
                  scroll: _scroll,
                  child: _HowItWorks(
                    eyebrow: 'For purohits',
                    title: 'Your knowledge,\nfinally easy to find',
                    accent: AppColors.maroon,
                    tint: const Color(0xFFF7ECEA),
                    steps: const [
                      _Step(
                        icon: Icons.badge_outlined,
                        title: 'Register and get verified',
                        body: 'Share your experience, your guru parampara and '
                            'your documents once. Verification is what earns a '
                            'family trust before you ever meet them.',
                      ),
                      _Step(
                        icon: Icons.work_outline,
                        title: 'See real requests near you',
                        body: 'Families post the ritual, the date and the place. '
                            'Set your travel radius and only see what you can '
                            'actually reach.',
                      ),
                      _Step(
                        icon: Icons.handshake_outlined,
                        title: 'Apply on your terms',
                        body: 'Quote your dakshina, answer questions in chat and '
                            'take only the work that suits your calendar.',
                      ),
                    ],
                  ),
                ),
                _Reveal(scroll: _scroll, child: const _TrustStrip()),
                _Reveal(scroll: _scroll, child: const _ClosingCta()),
              ],
            ),
          ),
          _TopBar(visible: _barVisible),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.scroll, required this.halo, required this.line});

  final ScrollController scroll;
  final AnimationController halo;
  final String line;

  @override
  Widget build(BuildContext context) {
    final height = math.max(560.0, MediaQuery.sizeOf(context).height * 0.86);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDF2E4), AppColors.surface],
              ),
            ),
          ),
          // Parallax: the mark drifts up slower than the text, which reads as
          // depth without needing a second scroll view.
          AnimatedBuilder(
            animation: scroll,
            builder: (context, child) {
              final offset = scroll.hasClients ? scroll.offset : 0.0;
              return Transform.translate(
                offset: Offset(0, offset * 0.28),
                child: Opacity(
                  opacity: (1 - offset / 420).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Align(
              alignment: const Alignment(0, -0.62),
              child: _HaloMark(halo: halo),
            ),
          ),
          AnimatedBuilder(
            animation: scroll,
            builder: (context, child) {
              final offset = scroll.hasClients ? scroll.offset : 0.0;
              return Transform.translate(
                offset: Offset(0, offset * 0.06),
                child: child,
              );
            },
            child: Align(
              alignment: const Alignment(0, 0.34),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Purohit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    // The rotating line is the one piece of copy that has to do
                    // the emotional work, so it gets the cross-fade.
                    SizedBox(
                      height: 76,
                      child: AnimatedSwitcher(
                        duration: AppDuration.slow,
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          line,
                          key: ValueKey(line),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    const _CtaPair(),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.94),
            child: _ScrollHint(halo: halo),
          ),
        ],
      ),
    );
  }
}

class _HaloMark extends StatelessWidget {
  const _HaloMark({required this.halo});

  final AnimationController halo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: halo,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(halo.value);
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(220 + 26 * t, 0.10 - 0.05 * t),
              _ring(168 + 18 * t, 0.16 - 0.06 * t),
              _ring(124 + 10 * t, 0.24 - 0.08 * t),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.marigold.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.temple_hindu,
          size: 50,
          color: AppColors.saffronDark,
        ),
      ),
    );
  }

  Widget _ring(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.marigold.withValues(alpha: alpha.clamp(0.0, 1.0)),
        ),
      );
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({required this.halo});

  final AnimationController halo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: halo,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(halo.value);
        return Transform.translate(
          offset: Offset(0, -6 + 12 * t),
          child: Opacity(opacity: 0.45 + 0.35 * t, child: child),
        );
      },
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Scroll to see how it works',
            style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
          ),
          SizedBox(height: Gap.xs),
          Icon(Icons.keyboard_arrow_down, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _WhatWeDo extends StatelessWidget {
  const _WhatWeDo({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    const cards = [
      _FeatureCard(
        icon: Icons.verified_outlined,
        title: 'Verified, not just listed',
        body: 'Every purohit submits documents and guru references before a '
            'single family can see them. Nobody appears on the app unreviewed.',
      ),
      _FeatureCard(
        icon: Icons.translate_outlined,
        title: 'Your language, your parampara',
        body: 'Filter by the languages a purohit speaks and the traditions they '
            'perform, so the ceremony sounds the way it does at home.',
      ),
      _FeatureCard(
        icon: Icons.price_change_outlined,
        title: 'Dakshina agreed upfront',
        body: 'Fees are stated before you book and discussed in chat. No '
            'awkward conversation on the morning of the puja.',
      ),
      _FeatureCard(
        icon: Icons.near_me_outlined,
        title: 'Purohits who can actually reach you',
        body: 'Each purohit sets a travel radius, so the people you see are the '
            'people who can be at your door on the day.',
      ),
    ];

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(label: 'What Purohit does', color: AppColors.saffron),
          const SizedBox(height: Gap.md),
          const Text(
            'A marketplace for the moments\nthat matter most',
            style: TextStyle(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Gap.md),
          const Text(
            'Finding a pandit still runs on phone numbers passed around the '
            'family. That works until you move cities, until the date is close, '
            'or until nobody is sure who actually knows the vidhi. Purohit puts '
            'that search in one place — and gives purohits a way to be found by '
            'the families who need them.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: Gap.xl),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in cards) ...[
                  Expanded(child: c),
                  if (c != cards.last) const SizedBox(width: Gap.md),
                ],
              ],
            )
          else
            Column(
              children: [
                for (final c in cards) ...[
                  c,
                  if (c != cards.last) const SizedBox(height: Gap.md),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.tint,
    required this.steps,
  });

  final String eyebrow;
  final String title;
  final Color accent;
  final Color tint;
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    return _Section(
      background: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(label: eyebrow, color: accent),
          const SizedBox(height: Gap.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Gap.xl),
          for (var i = 0; i < steps.length; i++) ...[
            _StepTile(index: i + 1, step: steps[i], accent: accent),
            if (i != steps.length - 1) const SizedBox(height: Gap.lg),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.accent,
  });

  final int index;
  final _Step step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(step.icon, size: 22, color: accent),
        ),
        const SizedBox(width: Gap.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. ${step.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                step.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.saffronDark),
          const SizedBox(height: Gap.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Gap.xs),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Container(
        padding: const EdgeInsets.all(Gap.xl),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nothing about a puja should be a gamble',
              style: TextStyle(
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Gap.lg),
            _TrustLine(
              icon: Icons.shield_outlined,
              text: 'Documents and guru references checked by our team before '
                  'a purohit is listed.',
            ),
            SizedBox(height: Gap.md),
            _TrustLine(
              icon: Icons.reviews_outlined,
              text: 'Reviews written only by families who actually completed a '
                  'booking.',
            ),
            SizedBox(height: Gap.md),
            _TrustLine(
              icon: Icons.lock_outline,
              text: 'One email, one account. A login is either a family or a '
                  'purohit — never quietly both.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.marigold),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClosingCta extends StatelessWidget {
  const _ClosingCta();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        children: [
          const Text(
            'Which side are you on?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Gap.sm),
          const Text(
            'Pick a door. You can always browse the ceremonies first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: Gap.xl),
          const _CtaPair(),
          const SizedBox(height: Gap.md),
          TextButton(
            onPressed: () => context.push('/browse'),
            child: const Text('Just browsing? See the ceremonies'),
          ),
          const SizedBox(height: Gap.xxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// The two doors. Repeated at the top and the bottom because a visitor who
/// reads the whole page should not have to scroll back up to act on it.
class _CtaPair extends StatelessWidget {
  const _CtaPair();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/start/user'),
            icon: const Icon(Icons.family_restroom, size: 20),
            label: const Text('Start as a user'),
          ),
        ),
        const SizedBox(height: Gap.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/start/purohit'),
            icon: const Icon(Icons.self_improvement, size: 20),
            label: const Text('Start as a purohit'),
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.background});

  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.xl,
        vertical: Gap.xxl + Gap.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: child,
        ),
      ),
    );
  }
}

/// Fades and lifts its child the first time it scrolls into view, then stops
/// listening. Cheap enough to wrap every section in.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.scroll, required this.child});

  final ScrollController scroll;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDuration.slow,
  );
  bool _played = false;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_check);
    // The first section is already on screen, so it never gets a scroll event.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_played || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.88) {
      _played = true;
      widget.scroll.removeListener(_check);
      _c.forward();
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 36 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Appears once the hero is gone so the two doors are never more than a tap
/// away, however far down the page someone has read.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDuration.normal,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            Gap.lg,
            MediaQuery.paddingOf(context).top + Gap.sm,
            Gap.lg,
            Gap.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            border: const Border(
              bottom: BorderSide(color: AppColors.hairline),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.temple_hindu,
                  size: 20, color: AppColors.saffronDark),
              const SizedBox(width: Gap.sm),
              const Text(
                'Purohit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/start/purohit'),
                child: const Text('Purohit'),
              ),
              const SizedBox(width: Gap.xs),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                ),
                onPressed: () => context.push('/start/user'),
                child: const Text('User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
