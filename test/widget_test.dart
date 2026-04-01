import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FairSplitterApp());

    expect(find.text('Fair Splitter'), findsOneWidget);
    expect(find.text('Новый счёт'), findsOneWidget);
  });
}
