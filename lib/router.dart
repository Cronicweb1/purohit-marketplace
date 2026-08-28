import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'features/auth/onboarding_page.dart';
import 'features/auth/sign_in_page.dart';
import 'features/auth/verify_otp_page.dart';
import 'features/jobs/job_detail_page.dart';
import 'features/jobs/jobs_feed_page.dart';
import 'features/jobs/my_work_page.dart';
import 'features/jobs/post_job_page.dart';
import 'features/profile/profile_page.dart';
import 'features/rituals/rituals_page.dart';
import 'features/shell/home_shell.dart';
import 'theme/app_theme.dart';

/// Branch indexes are a contract with [HomeShell], which hard-codes them.
/// 0 discover · 1 my work · 2 post · 3 profile.
final _rootKey = GlobalKey<NavigatorState>();

/// go_router's `redirect` cannot await, so the session must be readable
/// synchronously — that is why [SessionStatus] exists as a plain enum on a
/// `Notifier` instead of an `AsyncValue`.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProvider, (_, __) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/jobs',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionProvider).status;
      final loc = state.matchedLocation;

      const publicRoutes = {'/sign-in', '/verify', '/browse'};
      final isPublic = publicRoutes.contains(loc);

      switch (status) {
        case SessionStatus.unconfigured:
          return loc == '/setup' ? null : '/setup';
        case SessionStatus.loading:
          return null;
        case SessionStatus.signedOut:
          return isPublic ? null : '/sign-in';
        case SessionStatus.needsOnboarding:
          return loc == '/onboarding' ? null : '/onboarding';
        case SessionStatus.ready:
          if (loc == '/onboarding' || loc == '/setup' || isPublic) return '/jobs';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const _SetupPage()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(
        path: '/verify',
        builder: (_, state) =>
            VerifyOtpPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(
        path: '/browse',
        builder: (_, __) => const Scaffold(body: RitualsView(standalone: true)),
      ),
      GoRoute(
        path: '/jobs/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => JobDetailPage(
          jobId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/jobs', builder: (_, __) => const DiscoverPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/my-work', builder: (_, __) => const MyWorkPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/post',
              builder: (_, state) => PostJobPage(
                initialRitualId:
                    int.tryParse(state.uri.queryParameters['ritual'] ?? ''),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.uri.toString())),
    ),
  );
});

/// Shown when `.env` never loaded, so Supabase was never initialised. Without
/// this the app would just crash on the first `Supabase.instance` touch.
class _SetupPage extends StatelessWidget {
  const _SetupPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: AppColors.inkFaint),
              const SizedBox(height: Gap.lg),
              const Text(
                'Backend not configured',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Gap.sm),
              const Text(
                'This build was compiled without SUPABASE_URL and '
                'SUPABASE_ANON_KEY, so it cannot reach the database. Grab the '
                'APK from a workflow run that had the repository secrets set.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
