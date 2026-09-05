import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/session.dart';
import 'features/admin/admin_page.dart';
import 'features/admin/admin_sign_in_page.dart';
import 'features/auth/onboarding_page.dart';
import 'features/auth/role_register_page.dart';
import 'features/auth/role_sign_in_page.dart';
import 'features/auth/sign_in_page.dart';
import 'features/auth/verify_otp_page.dart';
import 'features/jobs/job_detail_page.dart';
import 'features/jobs/jobs_feed_page.dart';
import 'features/jobs/my_work_page.dart';
import 'features/jobs/purohit_jobs_page.dart';
import 'features/jobs/post_job_page.dart';
import 'features/landing/landing_page.dart';
import 'features/landing/role_gate_page.dart';
import 'features/messages/conversation_page.dart';
import 'features/messages/messages_page.dart';
import 'features/profile/profile_page.dart';
import 'features/purohit/purohit_public_page.dart';
import 'features/purohit/register_purohit_page.dart';
import 'features/rituals/ritual_detail_page.dart';
import 'features/rituals/rituals_page.dart';
import 'features/shell/home_shell.dart';
import 'models/profile.dart';
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
    // The marketing page. Signed-in users never see it: the `ready`
    // branch of the redirect below bounces '/' straight to '/jobs'.
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionProvider).status;
      final loc = state.matchedLocation;

      // `/admin-sign-in` is public for the same reason `/sign-in` is: you have
      // to reach it before you have a session.
      // The whole landing funnel is public by necessity — it is how a visitor
      // reaches a login form in the first place. Omitting any of these bounces
      // signed-out visitors to '/sign-in' the moment they tap a button.
      const publicRoutes = {
        '/',
        '/start/user',
        '/start/purohit',
        '/register/user',
        '/register/purohit',
        '/login/user',
        '/login/purohit',
        '/sign-in',
        '/verify',
        '/browse',
        '/admin-sign-in',
      };
      final isPublic = publicRoutes.contains(loc);

      // Ceremony detail sits between Browse and Post, so it has to be readable
      // in every session state: signed-out visitors (that is the entire point
      // of '/browse') and signed-in families alike. It cannot live in
      // `publicRoutes`, which is an exact-match set, and the `ready` branch
      // below would otherwise bounce it to '/jobs'.
      if (loc.startsWith('/ceremony/')) {
        return status == SessionStatus.unconfigured ? '/setup' : null;
      }

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
          // Signed in, so the landing funnel and the login forms have nothing
          // left to offer. VerifyOtpPage also lands on '/' and lets this decide.
          if (loc == '/' ||
              loc == '/onboarding' ||
              loc == '/setup' ||
              isPublic) {
            return '/jobs';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const _SetupPage()),
      GoRoute(path: '/', builder: (_, __) => const LandingPage()),

      // Two doors, kept as separate literal paths rather than one '/:role'
      // route so they can sit in the `publicRoutes` set above, which matches on
      // the resolved location.
      GoRoute(
        path: '/start/user',
        builder: (_, __) => const RoleGatePage(role: UserRole.family),
      ),
      GoRoute(
        path: '/start/purohit',
        builder: (_, __) => const RoleGatePage(role: UserRole.purohit),
      ),
      GoRoute(
        path: '/register/user',
        builder: (_, __) => const RoleRegisterPage(role: UserRole.family),
      ),
      GoRoute(
        path: '/register/purohit',
        builder: (_, __) => const RoleRegisterPage(role: UserRole.purohit),
      ),
      GoRoute(
        path: '/login/user',
        builder: (_, __) => const RoleSignInPage(role: UserRole.family),
      ),
      GoRoute(
        path: '/login/purohit',
        builder: (_, __) => const RoleSignInPage(role: UserRole.purohit),
      ),

      // Kept for the admin console and for any link already in the wild.
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(
        path: '/verify',
        builder: (_, state) => VerifyOtpPage(
          email: state.uri.queryParameters['email'] ?? '',
          type: state.uri.queryParameters['type'] == 'signup'
              ? OtpType.signup
              : OtpType.email,
        ),
      ),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(
        path: '/register-purohit',
        builder: (_, __) => const RegisterPurohitPage(),
      ),
      GoRoute(
        path: '/admin-sign-in',
        builder: (_, __) => const AdminSignInPage(),
      ),
      // Top-level, not a shell branch: [HomeShell] hard-codes four branch
      // indexes and go_router builds that list once, so a conditional fifth tab
      // would desync the index contract.
      GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
      GoRoute(
        path: '/browse',
        builder: (_, __) => const Scaffold(body: RitualsView(standalone: true)),
      ),
      // Pushed on the root navigator so it covers the shell: tapping a ceremony
      // in Browse should feel like opening a page, not switching tabs.
      GoRoute(
        path: '/ceremony/:slug',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            RitualDetailPage(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: '/jobs/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => JobDetailPage(
          jobId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/purohit/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => PurohitPublicPage(
          panditId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/messages/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ConversationPage(
          conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
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
          // Branch 4. Unconditional on purpose: both roles get Messages, so
          // the branch list stays the same length for everyone and the index
          // contract documented above holds.
          StatefulShellBranch(routes: [
            GoRoute(path: '/messages', builder: (_, __) => const MessagesPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/purohit-jobs',
              builder: (_, __) => const PurohitJobsPage(),
            ),
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
