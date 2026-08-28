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
  });

  final SessionStatus status;
  final Profile? profile;
  final PanditProfile? pandit;
  final String? email;

  /// Role is derived from the existence of a `pandit_profiles` row rather than
  /// stored on `profiles`. `auth.users.app_metadata` would be the "correct"
  /// place but is not client-writable, and `user_metadata` is client-writable
  /// and therefore useless for authorisation. The row is what `jobs_read`
  /// checks, so deriving from it keeps UI and RLS in lockstep.
  UserRole get role => pandit == null ? UserRole.family : UserRole.purohit;

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
    bool clearPandit = false,
  }) =>
      SessionState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        pandit: clearPandit ? null : (pandit ?? this.pandit),
        email: email ?? this.email,
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

    try {
      final profileRow = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url, city_id, locale')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow == null) {
        state = SessionState(
          status: SessionStatus.needsOnboarding,
          email: user.email,
        );
        return;
      }

      final panditRow = await supabase
          .from('pandit_profiles')
          .select(
            'id, status, bio, experience_years, base_fee, '
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
      );
    } catch (_) {
      // Offline or RLS surprise. Treat as signed-in-but-incomplete rather than
      // bouncing the user back to a login screen they already passed.
      state = SessionState(
        status: SessionStatus.needsOnboarding,
        email: user.email,
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
