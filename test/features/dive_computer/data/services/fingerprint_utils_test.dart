import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/dive_computer/data/services/fingerprint_utils.dart';
import 'package:submersion/features/dive_computer/domain/entities/downloaded_dive.dart';

void main() {
  group('selectNewestFingerprint', () {
    test('returns null for empty list', () {
      expect(selectNewestFingerprint([]), isNull);
    });

    test('returns null when no dives have fingerprints', () {
      final dives = [
        DownloadedDive(
          startTime: DateTime(2026, 1, 1),
          durationSeconds: 3600,
          maxDepth: 20.0,
          profile: [],
        ),
      ];
      expect(selectNewestFingerprint(dives), isNull);
    });

    test('returns fingerprint of the newest dive by startTime', () {
      final dives = [
        DownloadedDive(
          startTime: DateTime(2026, 1, 1, 10, 0),
          durationSeconds: 3600,
          maxDepth: 20.0,
          profile: [],
          fingerprint: 'aabb01',
        ),
        DownloadedDive(
          startTime: DateTime(2026, 1, 3, 14, 0),
          durationSeconds: 2400,
          maxDepth: 25.0,
          profile: [],
          fingerprint: 'ccdd02',
        ),
        DownloadedDive(
          startTime: DateTime(2026, 1, 2, 8, 0),
          durationSeconds: 1800,
          maxDepth: 15.0,
          profile: [],
          fingerprint: 'eeff03',
        ),
      ];
      expect(selectNewestFingerprint(dives), equals('ccdd02'));
    });

    test('skips dives without fingerprints when selecting newest', () {
      final dives = [
        DownloadedDive(
          startTime: DateTime(2026, 1, 5),
          durationSeconds: 3600,
          maxDepth: 30.0,
          profile: [],
          // no fingerprint
        ),
        DownloadedDive(
          startTime: DateTime(2026, 1, 3),
          durationSeconds: 2400,
          maxDepth: 20.0,
          profile: [],
          fingerprint: 'aabb01',
        ),
      ];
      expect(selectNewestFingerprint(dives), equals('aabb01'));
    });

    test('handles single dive with fingerprint', () {
      final dives = [
        DownloadedDive(
          startTime: DateTime(2026, 3, 1),
          durationSeconds: 3000,
          maxDepth: 18.0,
          profile: [],
          fingerprint: 'single01',
        ),
      ];
      expect(selectNewestFingerprint(dives), equals('single01'));
    });
  });
}
