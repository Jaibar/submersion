import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:submersion/core/deco/entities/deco_status.dart';
import 'package:submersion/core/deco/entities/tissue_compartment.dart';

/// A Subsurface-style tissue loading heat map that visualizes all 16
/// Bühlmann compartment loadings over the full dive duration.
///
/// Each row represents a tissue compartment (fast tissues at top, slow at
/// bottom). Each column represents a time point. Color encodes the tissue
/// loading relative to ambient pressure using Subsurface's two-phase scale:
/// - Below ambient (ongassing): cyan -> blue -> purple -> black
/// - Above ambient (offgassing): green -> yellow -> orange -> red
class TissueHeatMap extends StatelessWidget {
  /// Full time-series of decompression statuses across the dive
  final List<DecoStatus> decoStatuses;

  /// Currently selected point index (for cursor line)
  final int? selectedIndex;

  /// Chart height in logical pixels
  final double height;

  const TissueHeatMap({
    super.key,
    required this.decoStatuses,
    this.selectedIndex,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (decoStatuses.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Tissue Loading', style: textTheme.titleSmall),
                const Spacer(),
                TissueHeatMapLegend(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TissueHeatMapStrip(
              decoStatuses: decoStatuses,
              selectedIndex: selectedIndex,
              height: height,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fast',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
                Text(
                  'Slow',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Just the painted heat map strip without any card or labels.
///
/// Use this to embed the heat map inside another widget's layout.
class TissueHeatMapStrip extends StatelessWidget {
  /// Full time-series of decompression statuses across the dive
  final List<DecoStatus> decoStatuses;

  /// Currently selected point index (for cursor line)
  final int? selectedIndex;

  /// Strip height in logical pixels
  final double height;

  const TissueHeatMapStrip({
    super.key,
    required this.decoStatuses,
    this.selectedIndex,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (decoStatuses.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TissueHeatMapPainter(
            decoStatuses: decoStatuses,
            selectedIndex: selectedIndex,
            cursorColor: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Small legend showing the Subsurface heat map color scale.
///
/// Shows the two-phase color gradient: cool colors (ongassing) on the left,
/// warm colors (offgassing) on the right, with the ambient boundary marked.
class TissueHeatMapLegend extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const TissueHeatMapLegend({
    super.key,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Sample the color scale at many points to build a smooth gradient
    final colors = <Color>[];
    for (int i = 0; i <= 20; i++) {
      final pct = i * 5.0; // 0, 5, 10, ..., 100
      colors.add(subsurfaceHeatColor(pct));
    }

    final labelStyle = textTheme.labelSmall?.copyWith(
      fontSize: 9,
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('On', style: labelStyle),
        const SizedBox(width: 4),
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(colors: colors),
          ),
        ),
        const SizedBox(width: 4),
        Text('Off', style: labelStyle),
      ],
    );
  }
}

/// Efficiently paints the 2D tissue heat map using canvas operations.
///
/// Uses Subsurface's algorithm: each cell's color is derived from the tissue's
/// saturation relative to ambient pressure at that time point, mapped through
/// an HSV-based color scale.
class _TissueHeatMapPainter extends CustomPainter {
  final List<DecoStatus> decoStatuses;
  final int? selectedIndex;
  final Color cursorColor;

  _TissueHeatMapPainter({
    required this.decoStatuses,
    required this.selectedIndex,
    required this.cursorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (decoStatuses.isEmpty) return;

    final numTimePoints = decoStatuses.length;
    final numCompartments = decoStatuses.first.compartments.length;
    if (numCompartments == 0) return;

    final cellHeight = size.height / numCompartments;

    // For large datasets, sample columns to avoid painting thousands of
    // sub-pixel rectangles. Target roughly 1 column per logical pixel.
    final maxColumns = size.width.ceil();
    final step = numTimePoints > maxColumns ? numTimePoints / maxColumns : 1.0;

    final paint = Paint()..style = PaintingStyle.fill;

    double x = 0;
    double col = 0;
    while (col < numTimePoints) {
      final timeIdx = col.floor().clamp(0, numTimePoints - 1);
      final status = decoStatuses[timeIdx];
      final ambientPressure = status.ambientPressureBar;

      // Calculate next x position based on progress through time points
      final nextX = (col + step) / numTimePoints * size.width;
      final rectWidth = math.max(nextX - x, 1.0);

      for (int row = 0; row < numCompartments; row++) {
        final comp = status.compartments[row];
        final percentage = _subsurfacePercentage(comp, ambientPressure);
        paint.color = subsurfaceHeatColor(percentage);

        canvas.drawRect(
          Rect.fromLTWH(x, row * cellHeight, rectWidth, cellHeight),
          paint,
        );
      }

      x = nextX;
      col += step;
    }

    // Draw cursor line at selected index
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < numTimePoints) {
      final cursorX = (selectedIndex! + 0.5) / numTimePoints * size.width;
      final cursorPaint = Paint()
        ..color = cursorColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(cursorX, 0),
        Offset(cursorX, size.height),
        cursorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TissueHeatMapPainter oldDelegate) {
    return oldDelegate.decoStatuses != decoStatuses ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

/// Subsurface-style tissue percentage: two-phase normalization relative to
/// ambient pressure.
///
/// Returns a value where:
/// - 0-50: tissue is undersaturated (tension below ambient pressure)
///   Specifically: `(tension / ambient) * 50`
/// - 50: tissue is at equilibrium with ambient pressure
/// - 50-100: tissue is supersaturated (above ambient, up to M-value)
///   Specifically: `50 + gradientFactor * 50`
/// - >100: tissue tension exceeds M-value
double _subsurfacePercentage(TissueCompartment comp, double ambientPressure) {
  final tension = comp.totalInertGas;

  if (ambientPressure <= 0) return 50.0;

  if (tension < ambientPressure) {
    // Undersaturated: 0-50 range
    return (tension / ambientPressure) * 50.0;
  } else {
    // Supersaturated: 50-100+ range based on gradient factor to M-value
    final mValue = comp.blendedA + ambientPressure / comp.blendedB;
    if (mValue <= ambientPressure) return 50.0;
    final gf = (tension - ambientPressure) / (mValue - ambientPressure);
    return 50.0 + gf * 50.0;
  }
}

/// Subsurface's HSV-based color scale for tissue loading heat map.
///
/// This is a direct port of Subsurface's `colorScale()` function from
/// `profile-widget/divepercentageitem.cpp`. Uses full-saturation HSV colors.
///
/// Color mapping (for air, inert fraction = 0.79):
/// - 0 to ~31.6:    Cyan -> Blue -> Purple  (tissue far below ambient)
/// - ~31.6 to ~39.5: Magenta -> Black        (tissue near inspired gas pressure)
/// - ~39.5 to 50:    Black -> Green           (tissue between inspired and ambient)
/// - 50 to 65:       Green -> Yellow-green    (offgassing, 0-30% GF to M-value)
/// - 65 to 85:       Yellow-green -> Orange   (offgassing, 30-70% GF)
/// - 85 to 100:      Orange -> Red            (offgassing, 70-100% GF)
/// - 100 to 120:     Red -> White             (M-value exceeded)
/// - 120+:           White
Color subsurfaceHeatColor(double percentage, {double inertFraction = 0.79}) {
  // scaledValue represents tissue tension as a fraction of inspired inert gas
  // pressure. At 1.0, tissue tension equals inspired N2 at that depth.
  final scaledValue = percentage / (50.0 * inertFraction);

  if (scaledValue < 0.8) {
    // Cyan (180) -> Blue (225) -> Purple (270): far below ambient
    final h = (0.5 + 0.25 * scaledValue / 0.8) * 360.0;
    return HSVColor.fromAHSV(1.0, h.clamp(0.0, 360.0), 1.0, 1.0).toColor();
  }

  if (scaledValue < 1.0) {
    // Magenta (270) fading to black: near inspired gas pressure
    final v = ((1.0 - scaledValue) / 0.2).clamp(0.0, 1.0);
    return HSVColor.fromAHSV(1.0, 270.0, 1.0, v).toColor();
  }

  if (percentage < 50.0) {
    // Black -> Bright green (120): between inspired and ambient
    final threshold = 50.0 * inertFraction;
    final range = 50.0 - threshold;
    final v = range > 0
        ? ((percentage - threshold) / range).clamp(0.0, 1.0)
        : 0.0;
    return HSVColor.fromAHSV(1.0, 120.0, 1.0, v).toColor();
  }

  if (percentage < 65.0) {
    // Green (120) -> Yellow-green (72): 0-30% of GF toward M-value
    final h = (0.333 - 0.133 * (percentage - 50.0) / 15.0) * 360.0;
    return HSVColor.fromAHSV(1.0, h.clamp(0.0, 360.0), 1.0, 1.0).toColor();
  }

  if (percentage < 85.0) {
    // Yellow-green (72) -> Orange (36): 30-70% of GF toward M-value
    final h = (0.2 - 0.1 * (percentage - 65.0) / 20.0) * 360.0;
    return HSVColor.fromAHSV(1.0, h.clamp(0.0, 360.0), 1.0, 1.0).toColor();
  }

  if (percentage < 100.0) {
    // Orange (36) -> Red (0): 70-100% of GF toward M-value
    final h = (0.1 * (100.0 - percentage) / 15.0) * 360.0;
    return HSVColor.fromAHSV(1.0, h.clamp(0.0, 360.0), 1.0, 1.0).toColor();
  }

  if (percentage < 120.0) {
    // Red -> White: M-value exceeded
    final s = (1.0 - (percentage - 100.0) / 20.0).clamp(0.0, 1.0);
    return HSVColor.fromAHSV(1.0, 0.0, s, 1.0).toColor();
  }

  // White: well beyond M-value
  return const Color(0xFFFFFFFF);
}
