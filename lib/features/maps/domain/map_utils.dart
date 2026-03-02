import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Calculate an appropriate zoom level for a set of map points.
///
/// Uses a heuristic based on the maximum geographic span (latitude or
/// longitude) of the bounding box to select a discrete zoom level.
double calculateZoomForBounds(List<LatLng> points, LatLngBounds bounds) {
  if (points.length <= 1) return 12.0;

  final latSpan = bounds.north - bounds.south;
  final lngSpan = bounds.east - bounds.west;
  final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

  if (maxSpan > 5) return 4.0;
  if (maxSpan > 2) return 6.0;
  if (maxSpan > 1) return 7.0;
  if (maxSpan > 0.5) return 8.0;
  if (maxSpan > 0.2) return 9.0;
  if (maxSpan > 0.1) return 10.0;
  return 11.0;
}
