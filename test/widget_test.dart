import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/di/service_locator.dart';

void main() {
  testWidgets('FertiliteApp smoke test initialization', (WidgetTester tester) async {
    ServiceLocator.init();
    await tester.pumpWidget(const FertiliteApp());
    expect(find.byType(FertiliteApp), findsOneWidget);
  });
}
