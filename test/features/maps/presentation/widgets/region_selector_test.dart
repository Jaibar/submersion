import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:submersion/features/maps/presentation/widgets/region_selector.dart';
import 'package:submersion/l10n/arb/app_localizations.dart';

void main() {
  late MapController controller;
  LatLng? southWest;
  LatLng? northEast;

  setUp(() {
    controller = MapController();
    southWest = null;
    northEast = null;
  });

  Future<void> pumpSelector(
    WidgetTester tester, {
    bool selecting = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: controller,
                options: const MapOptions(
                  initialCenter: LatLng(0, 0),
                  initialZoom: 3,
                ),
                children: const [],
              ),
              RegionSelector(
                mapController: controller,
                selecting: selecting,
                onRegionSelected: (sw, ne) {
                  southWest = sw;
                  northEast = ne;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }

  // A pan starts after the touch slop, so the drawn corner sits a few pixels
  // past the press point. At zoom 3 that is a few degrees: compare loosely.
  const tolerance = 6.0;

  testWidgets('a drag draws a rectangle that Select Region reports', (
    tester,
  ) async {
    await pumpSelector(tester);

    await tester.dragFrom(const Offset(200, 200), const Offset(200, 150));
    await tester.pump();
    await confirm(tester);

    final topLeft = controller.camera.screenOffsetToLatLng(
      const Offset(200, 200),
    );
    final bottomRight = controller.camera.screenOffsetToLatLng(
      const Offset(400, 350),
    );
    expect(southWest, isNotNull);
    expect(southWest!.latitude, closeTo(bottomRight.latitude, tolerance));
    expect(southWest!.longitude, closeTo(topLeft.longitude, tolerance));
    expect(northEast!.latitude, closeTo(topLeft.latitude, tolerance));
    expect(northEast!.longitude, closeTo(bottomRight.longitude, tolerance));
  });

  testWidgets('dragging a corner moves it and keeps the opposite corner', (
    tester,
  ) async {
    await pumpSelector(tester);
    await tester.dragFrom(const Offset(200, 200), const Offset(200, 150));
    await tester.pump();

    // Pull the bottom-right corner out to (500, 400).
    await tester.dragFrom(const Offset(400, 350), const Offset(100, 50));
    await tester.pump();
    await confirm(tester);

    final topLeft = controller.camera.screenOffsetToLatLng(
      const Offset(200, 200),
    );
    final bottomRight = controller.camera.screenOffsetToLatLng(
      const Offset(500, 400),
    );
    expect(southWest!.latitude, closeTo(bottomRight.latitude, tolerance));
    expect(northEast!.longitude, closeTo(bottomRight.longitude, tolerance));
    // The opposite (top-left) corner stayed where it was drawn.
    expect(southWest!.longitude, closeTo(topLeft.longitude, tolerance));
    expect(northEast!.latitude, closeTo(topLeft.latitude, tolerance));
  });

  testWidgets('in move mode a drag draws nothing', (tester) async {
    await pumpSelector(tester, selecting: false);

    await tester.dragFrom(const Offset(200, 200), const Offset(200, 150));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
