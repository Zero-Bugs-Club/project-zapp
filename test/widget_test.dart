import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_zapp/main.dart';

void main() {
  testWidgets('App boots to the sign-in screen when logged out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ZappApp()));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Sign in'), findsWidgets);
  });
}
