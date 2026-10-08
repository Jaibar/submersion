import 'package:submersion/features/dive_log/data/services/profile_analysis_service.dart';
import 'package:submersion/features/dive_log/domain/entities/dive.dart';

/// What the diver wants to vary in the gas/GF "What if": the oxygen percentage
/// of the first (bottom-gas) cylinder and/or the gradient factors. A null
/// field keeps the logged value, so an all-null request is the dive as logged.
///
/// Value-equal so it can key a Riverpod family and cache each combination.
class GasGfOverrides {
  const GasGfOverrides({this.o2Percent, this.gfLow, this.gfHigh});

  /// Oxygen percentage (0-100) for the first cylinder; helium is kept.
  final double? o2Percent;
  final int? gfLow;
  final int? gfHigh;

  bool get isEmpty => o2Percent == null && gfLow == null && gfHigh == null;

  GasGfOverrides copyWith({
    double? o2Percent,
    int? gfLow,
    int? gfHigh,
    bool clearO2 = false,
    bool clearGfLow = false,
    bool clearGfHigh = false,
  }) => GasGfOverrides(
    o2Percent: clearO2 ? null : (o2Percent ?? this.o2Percent),
    gfLow: clearGfLow ? null : (gfLow ?? this.gfLow),
    gfHigh: clearGfHigh ? null : (gfHigh ?? this.gfHigh),
  );

  @override
  bool operator ==(Object other) =>
      other is GasGfOverrides &&
      other.o2Percent == o2Percent &&
      other.gfLow == gfLow &&
      other.gfHigh == gfHigh;

  @override
  int get hashCode => Object.hash(o2Percent, gfLow, gfHigh);
}

/// The first cylinder by [DiveTank.order]: the one the analysis starts the
/// dive on (`buildProfileGasSegments` and the analysis' primary gas both use
/// the first tank), so it is the one the O2 override replaces.
DiveTank? firstTank(Dive dive) {
  if (dive.tanks.isEmpty) return null;
  return ([...dive.tanks]..sort((a, b) => a.order.compareTo(b.order))).first;
}

/// [dive] with [overrides] applied. Tank ids are kept, so gas switches and
/// pressure series still resolve; only the mix and the dive's recorded GF
/// change. Setting the dive's GF pair makes `GradientFactorSource.resolve`
/// treat it as the computer's, which is what makes the override win over the
/// diver's settings.
Dive applyGasGfOverrides(Dive dive, GasGfOverrides overrides) {
  if (overrides.isEmpty) return dive;
  var tanks = dive.tanks;
  final o2 = overrides.o2Percent;
  final first = firstTank(dive);
  if (o2 != null && first != null) {
    // Clamp so o2 + he never exceeds 100 %.
    final mix = GasMix(
      o2: o2.clamp(0, 100 - first.gasMix.he),
      he: first.gasMix.he,
    );
    tanks = [
      for (final t in dive.tanks)
        t.id == first.id ? t.copyWith(gasMix: mix) : t,
    ];
  }
  final low = overrides.gfLow ?? dive.gradientFactorLow;
  final high = overrides.gfHigh ?? dive.gradientFactorHigh;
  return dive.copyWith(
    tanks: tanks,
    gradientFactorLow: low,
    gradientFactorHigh: high,
  );
}

/// The numbers that answer "how far from deco was I": one per analysis.
class GasGfWhatIfSummary {
  const GasGfWhatIfSummary({
    required this.minNdlSeconds,
    required this.minNdlIndex,
    required this.maxCeilingMeters,
    required this.hadDeco,
    required this.peakTissueLoadingPercent,
    required this.cnsEndPercent,
    required this.otu,
    required this.maxPpO2,
  });

  /// Shortest no-decompression limit over the dive; negative once in deco.
  final int minNdlSeconds;

  /// Index into the analysed profile samples where [minNdlSeconds] occurred
  /// (the analysis curves are aligned with the samples).
  final int minNdlIndex;

  final double maxCeilingMeters;
  final bool hadDeco;

  /// Highest leading-compartment loading, as % of its surface M-value.
  final double peakTissueLoadingPercent;
  final double cnsEndPercent;
  final double otu;
  final double maxPpO2;

  factory GasGfWhatIfSummary.fromAnalysis(ProfileAnalysis analysis) {
    var minNdl = 1 << 30;
    var minNdlIndex = 0;
    for (var i = 0; i < analysis.ndlCurve.length; i++) {
      if (analysis.ndlCurve[i] < minNdl) {
        minNdl = analysis.ndlCurve[i];
        minNdlIndex = i;
      }
    }
    var maxCeiling = 0.0;
    for (final c in analysis.ceilingCurve) {
      if (c > maxCeiling) maxCeiling = c;
    }
    var peak = 0.0;
    for (final s in analysis.decoStatuses) {
      if (s.leadingCompartmentLoading > peak)
        peak = s.leadingCompartmentLoading;
    }
    return GasGfWhatIfSummary(
      minNdlSeconds: analysis.ndlCurve.isEmpty ? 0 : minNdl,
      minNdlIndex: minNdlIndex,
      maxCeilingMeters: maxCeiling,
      hadDeco: analysis.hadDecoObligation,
      peakTissueLoadingPercent: peak,
      cnsEndPercent: analysis.o2Exposure.cnsEnd,
      otu: analysis.o2Exposure.otu,
      maxPpO2: analysis.o2Exposure.maxPpO2,
    );
  }
}
