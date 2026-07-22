import 'package:flutter_test/flutter_test.dart';
import 'package:multitrack/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MultiTrack app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AppBootstrap());
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
  });
}
