import 'package:flutter_test/flutter_test.dart';
import 'package:insta_counter_app/app.dart';
import 'package:insta_counter_app/core/constants/app_constants.dart';

void main() {
  testWidgets('Splash then dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaCounterApp());

    expect(find.text(AppConstants.appName), findsOneWidget);

    await tester.pump(AppConstants.splashDuration);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Dashboard'), findsWidgets);
  });
}
