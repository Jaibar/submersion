import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/backup/domain/entities/backup_settings.dart';

void main() {
  group('BackupSettings', () {
    test('defaults backupLocation to null', () {
      const settings = BackupSettings();
      expect(settings.backupLocation, isNull);
    });

    test('copyWith preserves backupLocation', () {
      const settings = BackupSettings(backupLocation: '/custom/path');
      final copied = settings.copyWith(enabled: true);
      expect(copied.backupLocation, '/custom/path');
    });

    test('copyWith overrides backupLocation', () {
      const settings = BackupSettings(backupLocation: '/old/path');
      final copied = settings.copyWith(backupLocation: '/new/path');
      expect(copied.backupLocation, '/new/path');
    });

    test('includes backupLocation in Equatable props', () {
      const a = BackupSettings(backupLocation: '/path/a');
      const b = BackupSettings(backupLocation: '/path/b');
      const c = BackupSettings(backupLocation: '/path/a');
      expect(a, isNot(equals(b)));
      expect(a, equals(c));
    });
  });
}
