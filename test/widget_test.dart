import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_cash/app.dart';
import 'package:track_cash/core/theme/theme_provider.dart';

void main() {
  testWidgets('TrackCash app loads and renders main navigation smoke test',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TrackCashApp(),
      ),
    );

    // Verify root navigation destinations exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Udhaar'), findsOneWidget);
  });
}
