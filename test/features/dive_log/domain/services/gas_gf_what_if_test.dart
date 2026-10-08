import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/features/dive_log/domain/entities/dive.dart';
import 'package:submersion/features/dive_log/domain/services/gas_gf_what_if.dart';

DiveTank _tank(String id, int order, GasMix mix) =>
    DiveTank(id: id, gasMix: mix, order: order);

Dive _dive() => Dive(
  id: 'd1',
  dateTime: DateTime(2026, 1, 1, 9),
  gradientFactorLow: 40,
  gradientFactorHigh: 85,
  tanks: [
    _tank('deco', 1, const GasMix(o2: 50)),
    _tank('back', 0, const GasMix(o2: 21, he: 10)),
  ],
);

void main() {
  group('applyGasGfOverrides', () {
    test('empty overrides return the dive untouched', () {
      final dive = _dive();
      expect(applyGasGfOverrides(dive, const GasGfOverrides()), same(dive));
    });

    test('O2 replaces the first cylinder by order and keeps helium', () {
      final out = applyGasGfOverrides(
        _dive(),
        const GasGfOverrides(o2Percent: 32),
      );
      final back = out.tanks.firstWhere((t) => t.id == 'back');
      final deco = out.tanks.firstWhere((t) => t.id == 'deco');
      expect(back.gasMix.o2, 32);
      expect(back.gasMix.he, 10);
      expect(deco.gasMix.o2, 50);
    });

    test('O2 is clamped so o2 + he never exceeds 100', () {
      final out = applyGasGfOverrides(
        _dive(),
        const GasGfOverrides(o2Percent: 100),
      );
      final back = out.tanks.firstWhere((t) => t.id == 'back');
      expect(back.gasMix.o2 + back.gasMix.he, 100);
    });

    test('GF override replaces one side and keeps the logged other', () {
      final out = applyGasGfOverrides(
        _dive(),
        const GasGfOverrides(gfHigh: 95),
      );
      expect(out.gradientFactorLow, 40);
      expect(out.gradientFactorHigh, 95);
    });
  });

  test('GasGfOverrides is value-equal so it can key a provider family', () {
    expect(
      const GasGfOverrides(o2Percent: 32, gfLow: 30),
      const GasGfOverrides(o2Percent: 32, gfLow: 30),
    );
    expect(
      const GasGfOverrides(o2Percent: 32).hashCode,
      const GasGfOverrides(o2Percent: 32).hashCode,
    );
  });
}
