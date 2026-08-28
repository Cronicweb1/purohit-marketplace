import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purohit/core/format.dart';
import 'package:purohit/main.dart';

void main() {
  // Supabase is never initialised in a widget test, so `supabaseReady` stays
  // false, the session reports `unconfigured`, and the router parks on /setup.
  // Asserting that is the cheapest proof the whole widget tree still builds.
  testWidgets('app boots without a backend', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PurohitApp()));
    await tester.pump();
    expect(find.text('Backend not configured'), findsOneWidget);
  });

  test('money uses Indian lakh grouping', () {
    expect(formatMoney(250000), contains('2,50,000'));
    expect(formatBudget(null), 'Open to quotes');
  });

  test('relative time is coarse', () {
    final now = DateTime.now();
    expect(timeAgo(now.subtract(const Duration(seconds: 5))), 'just now');
    expect(timeAgo(now.subtract(const Duration(hours: 3))), '3 hours ago');
  });

  test('initials fall back safely', () {
    expect(initialsOf('Ramesh Shastri'), 'RS');
    expect(initialsOf('Ramesh'), 'R');
    expect(initialsOf('   '), '?');
  });
}
