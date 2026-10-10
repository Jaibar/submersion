import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:submersion/features/maps/domain/map_utils.dart';

void main() {
  group('clampRegionToWorld', () {
    test('leaves a rectangle inside the world as it is', () {
      final region = clampRegionToWorld(
        const LatLng(10, 20),
        const LatLng(30, 40),
      );

      expect(region.southWest, const LatLng(10, 20));
      expect(region.northEast, const LatLng(30, 40));
    });

    test('moves a rectangle drawn on the next world east back', () {
      // Palau (134 E) seen one world copy to the east is at 494 E.
      final region = clampRegionToWorld(
        const LatLng(6, 493),
        const LatLng(8, 495),
      );

      expect(region.southWest.longitude, closeTo(133, 1e-9));
      expect(region.northEast.longitude, closeTo(135, 1e-9));
    });

    test('moves a rectangle drawn on the world to the west back', () {
      final region = clampRegionToWorld(
        const LatLng(6, -227),
        const LatLng(8, -225),
      );

      expect(region.southWest.longitude, closeTo(133, 1e-9));
      expect(region.northEast.longitude, closeTo(135, 1e-9));
    });

    test('cuts a rectangle that crosses the date line at 180', () {
      final region = clampRegionToWorld(
        const LatLng(-20, 170),
        const LatLng(-10, 190),
      );

      expect(region.southWest.longitude, 170);
      expect(region.northEast.longitude, 180);
    });

    test('holds latitudes to the web Mercator limit', () {
      final region = clampRegionToWorld(
        const LatLng(-89, 0),
        const LatLng(89, 10),
      );

      expect(region.southWest.latitude, closeTo(-85.0511, 1e-9));
      expect(region.northEast.latitude, closeTo(85.0511, 1e-9));
    });
  });
}
