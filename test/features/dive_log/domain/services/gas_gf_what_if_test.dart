import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/core/deco/ascent_rate_calculator.dart';
import 'package:submersion/core/deco/entities/o2_exposure.dart';
import 'package:submersion/features/dive_log/data/services/profile_analysis_service.dart';
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

ProfileAnalysis _analysis({
  List<int> ndlCurve = const [],
  List<double> ceilingCurve = const [],
  O2Exposure o2Exposure = const O2Exposure(),
}) {
  return ProfileAnalysis(
    ascentRates: const [],
    ascentRateStats: const AscentRateStats(
      maxAscentRate: 0,
      maxDescentRate: 0,
      averageAscentRate: 0,
      averageDescentRate: 0,
      violationCount: 0,
      criticalViolationCount: 0,
      timeInViolation: 0,
    ),
    ascentRateViolations: const [],
    events: const [],
    ceilingCurve: ceilingCurve,
    ndlCurve: ndlCurve,
    decoStatuses: const [],
    o2Exposure: o2Exposure,
    ppO2Curve: const [],
    maxDepth: 0,
    averageDepth: 0,
    maxDepthTimestamp: 0,
    durationSeconds: 0,
  );
}

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

  group('GasGfWhatIfSummary.fromAnalysis', () {
    test('finds the shortest NDL and where it happened', () {
      final summary = GasGfWhatIfSummary.fromAnalysis(
        _analysis(ndlCurve: const [999, 420, 95, 180, 600]),
      );

      expect(summary.minNdlSeconds, 95);
      expect(summary.minNdlIndex, 2);
      expect(summary.hadDeco, isFalse);
    });

    test('a negative NDL means the dive went into deco', () {
      final summary = GasGfWhatIfSummary.fromAnalysis(
        _analysis(
          ndlCurve: const [600, 30, -120, -60],
          ceilingCurve: const [0, 0, 3.2, 1.8],
        ),
      );

      expect(summary.minNdlSeconds, -120);
      expect(summary.hadDeco, isTrue);
      expect(summary.maxCeilingMeters, 3.2);
    });

    test('reads CNS, OTU and max ppO2 from the oxygen exposure', () {
      final summary = GasGfWhatIfSummary.fromAnalysis(
        _analysis(
          ndlCurve: const [600],
          o2Exposure: const O2Exposure(cnsEnd: 23, otu: 41, maxPpO2: 1.61),
        ),
      );

      expect(summary.cnsEndPercent, 23);
      expect(summary.otu, 41);
      expect(summary.maxPpO2, 1.61);
    });

    test('copes with an analysis that has no curves', () {
      final summary = GasGfWhatIfSummary.fromAnalysis(_analysis());

      expect(summary.minNdlSeconds, 0);
      expect(summary.maxCeilingMeters, 0);
      expect(summary.peakTissueLoadingPercent, 0);
    });
  });
}
