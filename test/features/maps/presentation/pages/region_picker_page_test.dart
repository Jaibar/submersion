import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/features/maps/presentation/pages/region_picker_page.dart';
import 'package:submersion/features/maps/presentation/widgets/map_style_button.dart';
import 'package:submersion/l10n/arb/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    final base = await getBaseOverrides();

    await tester.pumpWidget(
      ProviderScope(
        overrides: base,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegionPickerPage(),
        ),
      ),
    );

    // Avoid pumpAndSettle: the FlutterMap tile layer animates indefinitely.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('renders the RegionPickerPage FlutterMap', (tester) async {
    await pumpPage(tester);

    expect(find.byType(FlutterMap), findsWidgets);
  });

  testWidgets('offers the Move / Select toggle, zoom buttons and style', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(SegmentedButton<bool>), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byType(MapStyleButton), findsOneWidget);
  });

  testWidgets('starts in Move mode and switches to Select', (tester) async {
    await pumpPage(tester);

    SegmentedButton<bool> toggle() =>
        tester.widget(find.byType(SegmentedButton<bool>));
    expect(toggle().selected, {false});

    await tester.tap(find.byIcon(Icons.crop_free));
    await tester.pump();

    expect(toggle().selected, {true});
  });
}
