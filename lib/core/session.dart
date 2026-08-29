import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'supabase_providers.dart';

enum SessionStatus {
  /// Supabase was never initialised — `.env` is missing or malformed.
  unconfigured,

  /// Restoring a persisted session, or fetching the profile row.
  loading,
  signedOut,

  /// Authenticated, but there is no `profiles` row yet.
  needsOnboarding,
  ready,
}

class SessionState {
  const SessionState({
    required this.status,
    this.profile,
    this.pandit,
    this.email,
    this.isAdmin = false,
  });

  final SessionStatus status;
  final Profile? profile;
  final PanditProfile? pandit;
  final String? email;

  /// Read from `auth.users.app_metadata`, which only the service role can
  /// write. `user_metadata` is client-writable and therefore worthless for
  /// authorisation, and a `profiles.is_admin` column would be RLS-readable but
  /// still needs a round trip — the JWT already carries the answer.
  ///
  /// This flag only hides UI. Every admin action is re-checked server-side by
  /// `public.is_admin()` in RLS and by the `guard_pandit_status` trigger.
  final bool isAdmin;

  /// `profiles.account_type` is the primary answer, because a purohit who has
  /// only just registered has made their choice but does not own a
  /// `pandit_profiles` row yet — deriving from the row alone would drop them
  /// into the family app. The row is still honoured as a fallback so accounts
  /// created before the column existed keep working.
  ///
  /// `user_metadata` is client-writable and therefore useless for
  /// authorisation, but `account_type` is not: `guard_account_type` pins it
  /// after the signup trigger writes it, so this stays in lockstep with RLS.
  UserRole get role => profile?.accountType == UserRole.purohit || pandit != null
      ? UserRole.purohit
      : UserRole.family;

  /// True once a purohit has an actual listing. Registration creates the
  /// account first and the listing second, so the two are not the same thing.
  bool get hasPanditListing => pandit != null;

  bool get isPurohit => role == UserRole.purohit;

  /// An unapproved purohit gets an empty jobs feed no matter what the UI does —
  /// `jobs_read` requires `status = 'approved'`. Show a pending banner instead
  /// of a mystery blank list.
  bool get canSeeJobFeed => pandit?.isApproved ?? false;

  SessionState copyWith({
    SessionStatus? status,
    Profile? profile,
    PanditProfile? pandit,
    String? email,
    bool? isAdmin,
    bool clearPandit = false,
  }) =>
      SessionState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        pandit: clearPandit ? null : (pandit ?? this.pandit),
        email: email ?? this.email,
        isAdmin: isAdmin ?? this.isAdmin,
      );
}

class SessionController extends Notifier<SessionState> {
  StreamSubscription<AuthState>? _sub;

  @override
  SessionState build() {
    if (!supabaseReady) {
      return const SessionState(status: SessionStatus.unconfigured);
    }

    _sub = supabase.auth.onAuthStateChange.listen((_) => refresh());
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    // Cannot mutate `state` while build() is still running.
    Future.microtask(refresh);
    return const SessionState(status: SessionStatus.loading);
  }

  Future<void> refresh() async {
    if (!supabaseReady) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      state = const SessionState(status: SessionStatus.signedOut);
      return;
    }

    // Deliberately computed before the try block: it is a pure token read with
    // no network call, so an admin keeps the console even when the profile
    // fetch below fails.
    final isAdmin = user.appMetadata['role'] == 'admin';

    try {
      final profileRow = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url, city_id, locale, '
              'account_type, phone')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow == null) {
        state = SessionState(
          status: SessionStatus.needsOnboarding,
          email: user.email,
          isAdmin: isAdmin,
        );
        return;
      }

      final panditRow = await supabase
          .from('pandit_profiles')
          .select(
            'id, status, dob, bio, experience_years, base_fee, '
            'service_radius_km, languages, is_available',
          )
          .eq('id', user.id)
          .maybeSingle();

      state = SessionState(
        status: SessionStatus.ready,
        profile: Profile.fromMap(Map<String, dynamic>.from(profileRow)),
        pandit: panditRow == null
            ? null
            : PanditProfile.fromMap(Map<String, dynamic>.from(panditRow)),
        email: user.email,
        isAdmin: isAdmin,
      );
    } catch (_) {
      // Offline or RLS surprise. Treat as signed-in-but-incomplete rather than
      // bouncing the user back to a login screen they already passed.
      state = SessionState(
        status: SessionStatus.needsOnboarding,
        email: user.email,
        isAdmin: isAdmin,
      );
    }
  }

  Future<void> signOut() async {
    if (!supabaseReady) return;
    await supabase.auth.signOut();
    state = const SessionState(status: SessionStatus.signedOut);
  }
}

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
