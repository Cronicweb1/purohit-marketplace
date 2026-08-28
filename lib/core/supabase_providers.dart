import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True once `Supabase.initialize` has actually run.
///
/// It does NOT run when `.env` is missing — which is the case in CI when repo
/// secrets are absent, and in `flutter test`. Touching `Supabase.instance`
/// before initialisation throws, so every code path that reaches the network
/// must check this first. This is why the app degrades to a "not configured"
/// screen instead of crashing on launch.
bool supabaseReady = false;

SupabaseClient get supabase => Supabase.instance.client;

final supabaseProvider = Provider<SupabaseClient>((ref) => supabase);

/// Current user id, or null when signed out / unconfigured.
String? get currentUserId =>
    supabaseReady ? Supabase.instance.client.auth.currentUser?.id : null;
