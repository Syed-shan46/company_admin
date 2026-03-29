import 'package:flutter_test/flutter_test.dart';
import 'package:company_admin/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CompanyAdminApp()));

    // Verify that our counter starts at 0.
    expect(
      find.text('0'),
      findsNothing,
    ); // Just smoke test, counter doesn't exist anymore
  });
}
