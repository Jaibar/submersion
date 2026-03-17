import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/settings/data/services/dive_time_migration_service.dart';

void main() {
  group('DiveTimeMigrationService', () {
    group('computeShiftedEpoch', () {
      test('shifts epoch forward by positive hours', () {
        // 8:00 AM UTC
        final epoch = DateTime.utc(2024, 6, 15, 8, 0).millisecondsSinceEpoch;
        final shifted = DiveTimeMigrationService.computeShiftedEpoch(epoch, 3);
        final dt = DateTime.fromMillisecondsSinceEpoch(shifted, isUtc: true);
        expect(dt.hour, 11);
      });

      test('shifts epoch backward by negative hours', () {
        final epoch = DateTime.utc(2024, 6, 15, 8, 0).millisecondsSinceEpoch;
        final shifted = DiveTimeMigrationService.computeShiftedEpoch(epoch, -5);
        final dt = DateTime.fromMillisecondsSinceEpoch(shifted, isUtc: true);
        expect(dt.hour, 3);
      });

      test('handles date boundary crossing', () {
        final epoch = DateTime.utc(2024, 6, 15, 23, 0).millisecondsSinceEpoch;
        final shifted = DiveTimeMigrationService.computeShiftedEpoch(epoch, 3);
        final dt = DateTime.fromMillisecondsSinceEpoch(shifted, isUtc: true);
        expect(dt.day, 16);
        expect(dt.hour, 2);
      });
    });
  });
}
