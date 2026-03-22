import 'package:flutter_test/flutter_test.dart';

import 'package:planify_finance/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlaniFyApp());
    expect(find.byType(PlaniFyApp), findsOneWidget);
  });
}
