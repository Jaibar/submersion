import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:submersion/core/services/geocoding/nominatim_throttle.dart';
import 'package:submersion/core/services/location_service.dart';
import 'package:submersion/features/maps/data/services/tile_cache_service.dart';
import 'package:submersion/features/maps/domain/entities/cached_region.dart';
import 'package:submersion/features/maps/presentation/providers/offline_map_providers.dart';
import 'package:submersion/features/maps/presentation/widgets/region_download_dialog.dart';
import 'package:submersion/l10n/arb/app_localizations.dart';

import '../../../../helpers/fake_hosts.dart';
import '../../../../helpers/mock_providers.dart';

/// Answers every tile estimate with a fixed count.
class _FakeTileCache extends Fake implements TileCacheService {
  _FakeTileCache(this.tiles);

  final int tiles;

  @override
  Future<int> estimateTileCount({
    required LatLng southWest,
    required LatLng northEast,
    required int minZoom,
    required int maxZoom,
    required TileLayer options,
  }) async => tiles;
}

void main() {
  // The dialog suggests a name from the area's place, which asks Nominatim.
  // It answers as offline, as on a device without a network, with no wait.
  setUp(() {
    serveFakeHost('nominatim.openstreetmap.org');
    LocationService.throttle = NominatimThrottle(minimumGap: Duration.zero);
    addTearDown(() => LocationService.throttle = NominatimThrottle());
  });

  Future<void> pumpDialog(WidgetTester tester, {required int tiles}) async {
    final base = await getBaseOverrides();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base,
          tileCacheServiceProvider.overrideWithValue(_FakeTileCache(tiles)),
          cachedRegionsProvider.overrideWith((ref) async => <CachedRegion>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RegionDownloadDialog(
              southWest: LatLng(0, 0),
              northEast: LatLng(1, 1),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  ChoiceChip chip(WidgetTester tester, String label) =>
      tester.widget(find.widgetWithText(ChoiceChip, label));

  testWidgets('opens on the Overview preset', (tester) async {
    await pumpDialog(tester, tiles: 1000);

    expect(chip(tester, 'Overview').selected, isTrue);
    expect(chip(tester, 'Detail').selected, isFalse);
    expect(chip(tester, 'Full').selected, isFalse);
  });

  testWidgets('tapping a preset selects it', (tester) async {
    await pumpDialog(tester, tiles: 1000);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Detail'));
    await tester.pump();

    expect(chip(tester, 'Detail').selected, isTrue);
    expect(chip(tester, 'Overview').selected, isFalse);
  });

  testWidgets('Download is enabled below the tile limit', (tester) async {
    await pumpDialog(tester, tiles: 5000);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(find.textContaining('Over 100,000 tiles'), findsNothing);
  });

  testWidgets('Download is disabled above the tile limit', (tester) async {
    await pumpDialog(tester, tiles: 150000);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.textContaining('Over 100,000 tiles'), findsOneWidget);
  });
}
