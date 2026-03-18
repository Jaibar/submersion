import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';

void main() {
  group('AppSettings defaultTankPreset', () {
    test('has al80 as default', () {
      const settings = AppSettings();
      expect(settings.defaultTankPreset, 'al80');
    });

    test('has applyDefaultTankToImports false as default', () {
      const settings = AppSettings();
      expect(settings.applyDefaultTankToImports, false);
    });

    test('copyWith updates defaultTankPreset', () {
      const settings = AppSettings();
      final updated = settings.copyWith(defaultTankPreset: 'hp100');
      expect(updated.defaultTankPreset, 'hp100');
    });

    test('copyWith updates applyDefaultTankToImports', () {
      const settings = AppSettings();
      final updated = settings.copyWith(applyDefaultTankToImports: true);
      expect(updated.applyDefaultTankToImports, true);
    });

    test('copyWith can clear defaultTankPreset', () {
      const settings = AppSettings(defaultTankPreset: 'hp100');
      final updated = settings.copyWith(clearDefaultTankPreset: true);
      expect(updated.defaultTankPreset, null);
    });
  });
}
