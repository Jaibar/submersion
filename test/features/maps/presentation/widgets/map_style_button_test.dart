import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/core/constants/map_style.dart';
import 'package:submersion/features/maps/presentation/widgets/map_style_button.dart';
import 'package:submersion/l10n/arb/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

void main() {
  testWidgets('lists every map style and marks the current one', (
    tester,
  ) async {
    final base = await getBaseOverrides();

    await tester.pumpWidget(
      ProviderScope(
        overrides: base,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: MapStyleButton())),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    final items = tester
        .widgetList<CheckedPopupMenuItem<MapStyle>>(
          find.byType(CheckedPopupMenuItem<MapStyle>),
        )
        .toList();
    expect(items.map((i) => i.value), MapStyle.values);
    expect(items.where((i) => i.checked), hasLength(1));
  });
}
