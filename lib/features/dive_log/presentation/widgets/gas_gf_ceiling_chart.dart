import 'package:flutter/material.dart';

import 'package:submersion/core/utils/unit_formatter.dart';
import 'package:submersion/features/dive_log/domain/entities/dive.dart';

/// Depth profile with the logged and what-if decompression ceilings drawn on
/// the same axes, so the gap between the diver and the ceiling (how far from
/// deco) can be read directly. Depth increases downwards; the ceiling curves
/// are depths too, so a ceiling touching the profile means deco.
///
/// Hover (or drag) reports the sample index through [onHover]; [selectedIndex]
/// draws the cursor and both ceilings' values there, so the chart follows the
/// same shared cursor as the two dive profile charts.
class GasGfCeilingChart extends StatelessWidget {
  const GasGfCeilingChart({
    super.key,
    required this.profile,
    required this.loggedCeiling,
    required this.whatIfCeiling,
    required this.units,
    this.selectedIndex,
    this.onHover,
    this.height = 160,
  });

  final List<DiveProfilePoint> profile;

  /// Ceiling (m) per profile sample, same length as [profile].
  final List<double> loggedCeiling;
  final List<double> whatIfCeiling;
  final UnitFormatter units;
  final int? selectedIndex;
  final ValueChanged<int?>? onHover;
  final double height;

  /// Must match the painter's left gutter for the depth labels.
  static const double _labelWidth = 36.0;

  /// Nearest sample to horizontal position [dx], or null with no plot area.
  int? _indexAt(double dx, double width) {
    if (profile.length < 2 || width <= _labelWidth) return null;
    final t0 = profile.first.timestamp;
    final span = profile.last.timestamp - t0;
    if (span <= 0) return null;
    final fraction = ((dx - _labelWidth) / (width - _labelWidth)).clamp(
      0.0,
      1.0,
    );
    final target = t0 + fraction * span;
    var best = 0;
    var bestDiff = double.infinity;
    for (var i = 0; i < profile.length; i++) {
      final diff = (profile[i].timestamp - target).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return MouseRegion(
            onHover: (e) => onHover?.call(_indexAt(e.localPosition.dx, width)),
            onExit: (_) => onHover?.call(null),
            child: GestureDetector(
              onHorizontalDragUpdate: (d) =>
                  onHover?.call(_indexAt(d.localPosition.dx, width)),
              onTapDown: (d) =>
                  onHover?.call(_indexAt(d.localPosition.dx, width)),
              child: CustomPaint(
                painter: _CeilingPainter(
                  profile: profile,
                  loggedCeiling: loggedCeiling,
                  whatIfCeiling: whatIfCeiling,
                  units: units,
                  selectedIndex: selectedIndex,
                  profileColor: scheme.onSurfaceVariant,
                  loggedColor: scheme.primary,
                  whatIfColor: Colors.deepOrange,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CeilingPainter extends CustomPainter {
  _CeilingPainter({
    required this.profile,
    required this.loggedCeiling,
    required this.whatIfCeiling,
    required this.units,
    required this.selectedIndex,
    required this.profileColor,
    required this.loggedColor,
    required this.whatIfColor,
  });

  final List<DiveProfilePoint> profile;
  final List<double> loggedCeiling;
  final List<double> whatIfCeiling;
  final UnitFormatter units;
  final int? selectedIndex;
  final Color profileColor;
  final Color loggedColor;
  final Color whatIfColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.length < 2) return;
    final t0 = profile.first.timestamp;
    final span = (profile.last.timestamp - t0).toDouble();
    var maxDepth = 0.0;
    for (final p in profile) {
      if (p.depth > maxDepth) maxDepth = p.depth;
    }
    if (span <= 0 || maxDepth <= 0) return;

    const labelWidth = GasGfCeilingChart._labelWidth;
    final chartWidth = size.width - labelWidth;
    Offset at(int i, double depth) => Offset(
      labelWidth + (profile[i].timestamp - t0) / span * chartWidth,
      depth / maxDepth * size.height,
    );

    Path pathOf(double Function(int) depthAt) {
      final path = Path();
      for (var i = 0; i < profile.length; i++) {
        final o = at(i, depthAt(i));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      return path;
    }

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke;

    canvas.drawPath(pathOf((i) => profile[i].depth), stroke(profileColor, 1.5));
    // A ceiling shallower than the first sample is not drawn: it is 0 for most
    // of a no-deco dive and would just trace the surface.
    double ceilingAt(List<double> c, int i) => i < c.length ? c[i] : 0.0;
    canvas.drawPath(
      pathOf((i) => ceilingAt(loggedCeiling, i)),
      stroke(loggedColor, 2),
    );
    canvas.drawPath(
      pathOf((i) => ceilingAt(whatIfCeiling, i)),
      stroke(whatIfColor, 2),
    );

    final selected = selectedIndex;
    if (selected != null && selected < profile.length) {
      final x = at(selected, 0).dx;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        stroke(profileColor.withValues(alpha: 0.6), 1),
      );
      // Both ceilings at the cursor, top of the plot: logged / what-if.
      final readout = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          children: [
            TextSpan(
              text: units.formatDepth(ceilingAt(loggedCeiling, selected)),
              style: TextStyle(color: loggedColor),
            ),
            TextSpan(
              text: '  /  ',
              style: TextStyle(color: profileColor),
            ),
            TextSpan(
              text: units.formatDepth(ceilingAt(whatIfCeiling, selected)),
              style: TextStyle(color: whatIfColor),
            ),
          ],
        ),
      )..layout();
      final dx = (x + 6 + readout.width > size.width)
          ? x - 6 - readout.width
          : x + 6;
      readout.paint(canvas, Offset(dx, 2));
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final f in [0.0, 0.5, 1.0]) {
      tp.text = TextSpan(
        text: units.formatDepth(maxDepth * f, decimals: 0),
        style: TextStyle(color: profileColor, fontSize: 9),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, f * size.height - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CeilingPainter old) =>
      old.profile != profile ||
      old.selectedIndex != selectedIndex ||
      old.loggedCeiling != loggedCeiling ||
      old.whatIfCeiling != whatIfCeiling;
}
