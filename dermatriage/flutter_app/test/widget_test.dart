// Basic smoke test for the DermaTriage root widget.
import 'package:dermatriage/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const DermaTriage());
    expect(find.byType(DermaTriage), findsOneWidget);
  });
}
