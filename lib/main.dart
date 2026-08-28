import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env holds ONLY the anon key — never the service_role key, which bypasses
  // every RLS policy in the database.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Absent in CI without secrets. The app still builds so the pipeline stays
    // green; the router then parks on /setup instead of crashing.
  }

  final url = dotenv.maybeGet('SUPABASE_URL');
  final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

  if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
    // TODO(auth): `anonKey` is deprecated in favour of `publishableKey` and is
    // removed in supabase_flutter v3. Switch when you bump the major version —
    // the new param needs the `sb_publishable_...` key from Settings > API, not
    // the legacy JWT anon key, so both the code AND .env change together.
    // ignore: deprecated_member_use
    await Supabase.initialize(url: url, anonKey: anonKey);

    // Every repository and the session controller short-circuit on this flag.
    // Touching `Supabase.instance` before initialize() throws, and widget tests
    // never initialise it at all.
    supabaseReady = true;
  }

  runApp(const ProviderScope(child: PurohitApp()));
}

class PurohitApp extends ConsumerWidget {
  const PurohitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Purohit',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
