import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/features/maps/data/services/tile_cache_service.dart';
import 'package:submersion/features/maps/presentation/providers/map_tile_providers.dart';
import 'package:submersion/features/maps/presentation/widgets/map_attribution.dart';
import 'package:submersion/features/maps/presentation/widgets/map_style_button.dart';
import 'package:submersion/features/maps/presentation/widgets/region_download_dialog.dart';
import 'package:submersion/features/maps/presentation/widgets/region_selector.dart';
import 'package:submersion/features/maps/presentation/widgets/trackpad_zoom_map.dart';
import 'package:submersion/l10n/l10n_extension.dart';

/// Page for selecting a rectangular region on a map and opening the
/// [RegionDownloadDialog] for that region.
///
/// It has two modes, switched by the toggle at the top:
/// - Move: drag to pan, pinch / double-tap / the +/- buttons to zoom.
/// - Select: drag to draw the download rectangle, or drag one of its corner
///   handles to adjust it. Confirm to launch the download dialog.
///
/// Mouse and keyboard: wheel and double-click zoom, `+` / `-` (also on the
/// numpad) zoom in and out, and the middle button pans in Select mode too.
///
/// The rectangle is stored as coordinates, so it stays put on the map while
/// the map is moved. The page starts in Move mode so the diver can first
/// navigate to the area (Palau, the Bahamas) before drawing.
class RegionPickerPage extends ConsumerStatefulWidget {
  const RegionPickerPage({super.key});

  @override
  ConsumerState<RegionPickerPage> createState() => _RegionPickerPageState();
}

class _RegionPickerPageState extends ConsumerState<RegionPickerPage> {
  /// Lowest zoom the picker allows: the whole world.
  static const double _minZoom = 2.0;

  final MapController _mapController = MapController();

  bool _selecting = false;

  /// Bumped on every camera change so the selection rectangle repaints at its
  /// new screen position.
  int _cameraTick = 0;

  Future<void> _onRegionSelected(LatLng southWest, LatLng northEast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          RegionDownloadDialog(southWest: southWest, northEast: northEast),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final maxZoom = ref.read(mapTileMaxZoomProvider).toDouble();
    final zoom = (camera.zoom + delta).clamp(_minZoom, maxZoom);
    _mapController.move(camera.center, zoom);
  }

  /// Called by flutter_map on every camera change, possibly during a layout
  /// pass, so the rebuild is deferred to after the frame.
  void _onCameraChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _cameraTick++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Select mode keeps only the gestures that cannot clash with drawing;
    // Move mode gives the map every gesture except rotation.
    final flags = _selecting
        ? InteractiveFlag.pinchZoom |
              InteractiveFlag.pinchMove |
              InteractiveFlag.doubleTapZoom
        : InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.pinchMove |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.scrollWheelZoom;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.maps_offline_downloadNewRegion)),
      body: Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.equal): () => _zoomBy(1),
            const SingleActivator(LogicalKeyboardKey.add): () => _zoomBy(1),
            const SingleActivator(LogicalKeyboardKey.numpadAdd): () =>
                _zoomBy(1),
            const SingleActivator(LogicalKeyboardKey.minus): () => _zoomBy(-1),
            const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
                _zoomBy(-1),
          },
          child: Stack(
            children: [
              TrackpadZoomMap(
                controller: _mapController,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(20.0, 0.0),
                    initialZoom: 2.0,
                    minZoom: _minZoom,
                    maxZoom: ref.watch(mapTileMaxZoomProvider),
                    interactionOptions: InteractionOptions(flags: flags),
                    onPositionChanged: (camera, hasGesture) =>
                        _onCameraChanged(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: ref.watch(mapTileUrlProvider),
                      userAgentPackageName: 'app.submersion',
                      maxZoom: ref.watch(mapTileMaxZoomProvider),
                      tileProvider: TileCacheService.instance.tileProviderFor(
                        urlTemplate: ref.watch(mapTileUrlProvider),
                      ),
                    ),
                    const MapAttribution(),
                  ],
                ),
              ),
              RegionSelector(
                mapController: _mapController,
                onRegionSelected: _onRegionSelected,
                selecting: _selecting,
                cameraTick: _cameraTick,
              ),
              // Mode toggle, under the instruction card.
              Positioned(
                top: 88,
                left: 16,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.open_with),
                      label: Text(l10n.maps_regionSelector_modeMove),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.crop_free),
                      label: Text(l10n.maps_regionSelector_modeSelect),
                    ),
                  ],
                  selected: {_selecting},
                  onSelectionChanged: (value) =>
                      setState(() => _selecting = value.first),
                ),
              ),
              // Map style (Street / Topo / Satellite), top right under the
          // instruction card. It changes the app-wide style, so the tiles here
          // and the tiles a download fetches are the same style.
          const Positioned(top: 88, right: 16, child: MapStyleButton()),
          // Zoom buttons, above the action buttons.
              Positioned(
                right: 16,
                bottom: 96,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: null,
                      tooltip: l10n.maps_regionSelector_zoomIn,
                      onPressed: () => _zoomBy(1),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: null,
                      tooltip: l10n.maps_regionSelector_zoomOut,
                      onPressed: () => _zoomBy(-1),
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
