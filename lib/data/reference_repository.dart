import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/city.dart';
import '../models/institution.dart';
import '../models/ritual.dart';

/// Cities and rituals are the only tables readable with the anon key, so these
/// two providers are what make the app show something before sign-in.
class ReferenceRepository {
  const ReferenceRepository();

  Future<List<Ritual>> rituals() async {
    if (!supabaseReady) return const [];
    final res = await supabase
        .from('rituals')
        .select(
          'id, slug, name, name_hi, aliases, bookable, claimable, '
          'typical_duration_minutes, is_multi_day',
        )
        .eq('is_active', true)
        .order('sort_order')
        .order('name');
    return (res as List)
        .map((e) => Ritual.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<City>> cities() async {
    if (!supabaseReady) return const [];
    final res = await supabase
        .from('cities')
        .select('id, name, state')
        .eq('is_active', true)
        .order('name');
    return (res as List)
        .map((e) => City.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Gurukuls, Veda Pathashalas and Sanskrit universities. Anon-readable for
  /// the same reason cities are: the registration form needs it before the
  /// purohit has a `pandit_profiles` row to be authorised against.
  Future<List<Institution>> institutions() async {
    if (!supabaseReady) return const [];
    final res = await supabase
        .from('institutions')
        .select('id, name, city, state, kind')
        .eq('is_active', true)
        .order('name');
    return (res as List)
        .map((e) => Institution.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final referenceRepositoryProvider =
    Provider<ReferenceRepository>((ref) => const ReferenceRepository());

final ritualsProvider = FutureProvider<List<Ritual>>(
  (ref) => ref.watch(referenceRepositoryProvider).rituals(),
);

final citiesProvider = FutureProvider<List<City>>(
  (ref) => ref.watch(referenceRepositoryProvider).cities(),
);

final institutionsProvider = FutureProvider<List<Institution>>(
  (ref) => ref.watch(referenceRepositoryProvider).institutions(),
);

/// Only the rituals a family can actually post a job for.
final bookableRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final all = await ref.watch(ritualsProvider.future);
  return all.where((r) => r.bookable).toList();
});

/// Only the rituals a purohit may list as a specialisation. Vedic Knowledge,
/// Jyotishacharya, Kathavachak and Karmakandi live here but are not bookable.
final claimableRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final all = await ref.watch(ritualsProvider.future);
  return all.where((r) => r.claimable).toList();
});
