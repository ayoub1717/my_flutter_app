import 'package:flutter_test/flutter_test.dart';
import 'package:bargou_gym/home_page.dart';

void main() {
  testWidgets('HomePage smoke test', (WidgetTester tester) async {
    // dummy userData
    final Map dummyData = {
      "name": "Test",
      "tel": "123456",
      "sex": "Male",
      "start_date": "2026-03-01",
      "end_date": "2026-03-31",
    };

    await tester.pumpWidget(HomePage(userData: dummyData));
    expect(find.byType(HomePage), findsOneWidget);
  });
}