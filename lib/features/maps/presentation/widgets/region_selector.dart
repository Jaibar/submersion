import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:submersion/features/maps/domain/map_utils.dart';
import 'package:submersion/l10n/l10n_extension.dart';

/// Callback for when a region is selected.
typedef RegionSelectedCallback =
    void Function(LatLng southWest, LatLng northEast);

/// Widget for selecting a rectangular region on a map.
///
/// Two modes, switched by [selecting]:
/// - Select (true): a drag on the map draws a new rectangle, unless it starts
///   on one of the rectangle's four corner handles, in which case that corner
///   follows the finger and the opposite corner stays put. The drawing layer
///   sits above the map, so the map itself cannot be panned in this mode.
///
/// Mouse: the cursor turns into a crosshair in select mode and into a grab hand
/// over a corner handle, the corner grab area is smaller for a mouse than for a
/// finger, and the middle button pans the map even in select mode.
///
/// - Move (false): the drawing layer is removed, so drags and pinches reach the
///   map and it can be panned and zoomed. The rectangle stays drawn and follows
///   the map (it is stored as coordinates, and [cameraTick] makes it repaint).
class RegionSelector extends StatefulWidget {
  final MapController mapController;
  final RegionSelectedCallback? onRegionSelected;
  final VoidCallback? onCancel;
  final bool selecting;

  /// Changes whenever the map camera moves, so the rectangle is repainted at
  /// its new screen position.
  final int cameraTick;

  const RegionSelector({
    super.key,
    required this.mapController,
    this.onRegionSelected,
    this.onCancel,
    this.selecting = true,
    this.cameraTick = 0,
  });

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  /// A drag that starts within this many logical pixels of a corner handle
  /// grabs it. Generous, because a fingertip is much bigger than the dot.
  static const double _cornerGrabRadius = 36;

  /// A mouse is precise, so its grab area is much smaller; a big one would make
  /// it impossible to start a new rectangle near an existing corner.
  static const double _cornerGrabRadiusMouse = 14;

  LatLng? _startPoint;
  LatLng? _endPoint;
  bool _isDragging = false;

  /// Mouse is over a corner handle (changes the cursor to a grab hand).
  bool _hoverCorner = false;

  /// The middle mouse button is held and moving: pan the map by hand, because
  /// the drawing layer above the map takes the primary-button drags.
  bool _middlePanning = false;

  LatLng? get _southWest {
    if (_startPoint == null || _endPoint == null) return null;
    return LatLng(
      math.min(_startPoint!.latitude, _endPoint!.latitude),
      math.min(_startPoint!.longitude, _endPoint!.longitude),
    );
  }

  LatLng? get _northEast {
    if (_startPoint == null || _endPoint == null) return null;
    return LatLng(
      math.max(_startPoint!.latitude, _endPoint!.latitude),
      math.max(_startPoint!.longitude, _endPoint!.longitude),
    );
  }

  /// The four corners as (corner, opposite corner) pairs. Dragging a corner
  /// keeps its opposite fixed, whichever way the rectangle is then pulled.
  List<(LatLng, LatLng)> _cornerPairs() {
    final sw = _southWest!;
    final ne = _northEast!;
    final nw = LatLng(ne.latitude, sw.longitude);
    final se = LatLng(sw.latitude, ne.longitude);
    return [(sw, ne), (ne, sw), (nw, se), (se, nw)];
  }

  /// The corner pair whose handle is nearest [localPos] and within the grab
  /// radius, or null when the press is not on a handle.
  (LatLng, LatLng)? _cornerNear(Offset localPos, double radius) {
    if (_southWest == null || _northEast == null) return null;
    final camera = widget.mapController.camera;
    (LatLng, LatLng)? best;
    var bestDistance = radius;
    for (final pair in _cornerPairs()) {
      final distance =
          (camera.latLngToScreenOffset(pair.$1) - localPos).distance;
      if (distance <= bestDistance) {
        bestDistance = distance;
        best = pair;
      }
    }
    return best;
  }

  void _onPanStart(DragStartDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final radius = details.kind == PointerDeviceKind.mouse
        ? _cornerGrabRadiusMouse
        : _cornerGrabRadius;
    final corner = _cornerNear(localPos, radius);
    setState(() {
      if (corner != null) {
        // Grab the corner where it is (no jump), pinned to its opposite.
        _startPoint = corner.$2;
        _endPoint = corner.$1;
      } else {
        final point = widget.mapController.camera.screenOffsetToLatLng(
          localPos,
        );
        _startPoint = point;
        _endPoint = point;
      }
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final point = widget.mapController.camera.screenOffsetToLatLng(localPos);
    setState(() {
      _endPoint = point;
    });
  }

  void _onHover(PointerHoverEvent event) {
    final over =
        _cornerNear(event.localPosition, _cornerGrabRadiusMouse) != null;
    if (over != _hoverCorner) setState(() => _hoverCorner = over);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton) _middlePanning = true;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_middlePanning) return;
    final camera = widget.mapController.camera;
    final size = (context.findRenderObject() as RenderBox).size;
    // Dragging the map right means the view centre moves left by the same
    // number of pixels, hence centre - delta.
    final centre = Offset(size.width / 2, size.height / 2);
    widget.mapController.move(
      camera.screenOffsetToLatLng(centre - event.delta),
      camera.zoom,
    );
  }

  void _onPointerUp(PointerEvent event) {
    _middlePanning = false;
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  void _confirmSelection() {
    if (_southWest != null && _northEast != null) {
      final region = clampRegionToWorld(_southWest!, _northEast!);
      widget.onRegionSelected?.call(region.southWest, region.northEast);
    }
  }

  void _clearSelection() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
    });
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _southWest != null && _northEast != null;
    final l10n = context.l10n;

    final String instruction;
    if (!widget.selecting) {
      instruction = l10n.maps_regionSelector_dragToMove;
    } else if (hasSelection) {
      instruction = l10n.maps_regionSelector_dragToAdjust;
    } else {
      instruction = l10n.maps_regionSelector_dragToSelect;
    }

    return Stack(
      children: [
        // Drawing layer: only in select mode, otherwise it would swallow the
        // drags the map needs for panning.
        if (widget.selecting)
          Positioned.fill(
            child: Semantics(
              label: l10n.maps_regionSelector_selectRegion,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: MouseRegion(
                  cursor: _hoverCorner
                      ? SystemMouseCursors.grab
                      : SystemMouseCursors.precise,
                  onHover: _onHover,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                  ),
                ),
              ),
            ),
          ),

        // Selection rectangle overlay. IgnorePointer: it is only a picture and
        // must never block touches meant for the map or the drawing layer.
        if (hasSelection)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectionPainter(
                  southWest: _southWest!,
                  northEast: _northEast!,
                  mapController: widget.mapController,
                  color: colorScheme.primary,
                  cameraTick: widget.cameraTick,
                ),
              ),
            ),
          ),

        // Instructions overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearSelection,
                  child: Text(context.l10n.common_action_cancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: hasSelection ? _confirmSelection : null,
                  child: Text(
                    context.l10n.maps_regionSelector_selectRegionButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painter for the selection rectangle.
class _SelectionPainter extends CustomPainter {
  final LatLng southWest;
  final LatLng northEast;
  final MapController mapController;
  final Color color;
  final int cameraTick;

  _SelectionPainter({
    required this.southWest,
    required this.northEast,
    required this.mapController,
    required this.color,
    required this.cameraTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final camera = mapController.camera;

    final swPoint = camera.latLngToScreenOffset(southWest);
    final nePoint = camera.latLngToScreenOffset(northEast);

    final rect = Rect.fromPoints(
      Offset(swPoint.dx, nePoint.dy),
      Offset(nePoint.dx, swPoint.dy),
    );

    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, borderPaint);

    // Corner handles: drawn large with a white ring so they read as grabbable.
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const handleRadius = 9.0;

    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(corner, handleRadius, handlePaint);
      canvas.drawCircle(corner, handleRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return southWest != oldDelegate.southWest ||
        northEast != oldDelegate.northEast ||
        cameraTick != oldDelegate.cameraTick;
  }
}
