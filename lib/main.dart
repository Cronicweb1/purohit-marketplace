import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env holds ONLY the anon key — never the service_role key, which bypasses
  // every RLS policy in the database.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Absent in CI. The app still builds so the pipeline stays green.
  }

  final url = dotenv.maybeGet('SUPABASE_URL');
  final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

  if (url != null && anonKey != null) {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  runApp(const ProviderScope(child: PurohitApp()));
}

class PurohitApp extends StatelessWidget {
  const PurohitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purohit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8860B)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configured = dotenv.isInitialized &&
        dotenv.maybeGet('SUPABASE_URL') != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Purohit')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.temple_hindu, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Purohit Marketplace',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                configured
                    ? 'Supabase connected.'
                    : 'No .env found — copy .env.example to .env.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
