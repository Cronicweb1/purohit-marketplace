import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_providers.dart';
import '../models/portfolio_item.dart';

/// Work photos a purohit publishes on their public profile.
///
/// `portfolio_read` is `using (true)`, so a family browsing an applicant needs
/// no extra grant; `portfolio_write` pins every mutation to `auth.uid()`.
class PortfolioRepository {
  const PortfolioRepository();

  Future<List<PortfolioItem>> items(String panditId) async {
    if (!supabaseReady) return const [];

    final res = await supabase
        .from('portfolio_items')
        .select('id, pandit_id, object_path, caption, sort_order')
        .eq('pandit_id', panditId)
        .order('sort_order', ascending: true)
        .order('id', ascending: false);
    return (res as List)
        .map((e) => PortfolioItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> add({required String objectPath, String? caption}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Sign in first.');

    await supabase.from('portfolio_items').insert({
      'pandit_id': uid,
      'object_path': objectPath,
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
    });
  }

  Future<void> remove(int id) async {
    await supabase.from('portfolio_items').delete().eq('id', id);
  }
}

final portfolioRepositoryProvider =
    Provider<PortfolioRepository>((ref) => const PortfolioRepository());

final portfolioProvider = FutureProvider.family<List<PortfolioItem>, String>(
  (ref, panditId) => ref.watch(portfolioRepositoryProvider).items(panditId),
);
