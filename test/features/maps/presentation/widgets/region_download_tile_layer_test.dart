import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/features/maps/presentation/widgets/region_download_dialog.dart';

void main() {
  group('regionDownloadTileLayer', () {
    test('keeps the url template and max zoom it was given', () {
      final layer = regionDownloadTileLayer(
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        maxZoom: 16,
      );

      expect(layer.urlTemplate, 'https://example.test/{z}/{x}/{y}.png');
      expect(layer.maxZoom, 16);
    });

    test('uses a client-free provider, so FMTC can send it to its isolate', () {
      final layer = regionDownloadTileLayer(
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        maxZoom: 16,
      );

      // NetworkTileProvider owns an HTTP client; on Windows that client holds a
      // SecurityContext, which cannot cross Isolate.spawn.
      expect(layer.tileProvider, isA<DownloadTileProvider>());
      expect(layer.tileProvider, isNot(isA<NetworkTileProvider>()));
    });

    test('still sends a User-Agent in the provider headers', () {
      final layer = regionDownloadTileLayer(
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        maxZoom: 16,
      );

      // FMTC copies these headers onto every tile request it makes.
      expect(layer.tileProvider.headers['User-Agent'], contains('app.submersion'));
    });
  });
}
