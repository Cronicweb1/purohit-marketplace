import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purohit/main.dart';

void main() {
  testWidgets('app renders its title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PurohitApp()));
    expect(find.text('Purohit Marketplace'), findsOneWidget);
  });
}
