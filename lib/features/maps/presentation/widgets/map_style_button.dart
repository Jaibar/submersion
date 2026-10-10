import 'package:flutter/material.dart';

import 'package:submersion/core/constants/map_style.dart';
import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';
import 'package:submersion/l10n/l10n_extension.dart';

/// Small overlay button that switches the map style (Street, Topo, Satellite)
/// from the map itself.
///
/// It changes the same app-wide setting as Settings > Appearance > Map style,
/// so every map follows it. Sized like the fullscreen button next to it (a 20 px
/// icon in a 6 px padded square) so the two line up.
class MapStyleButton extends ConsumerWidget {
  const MapStyleButton({super.key});

  String _label(BuildContext context, MapStyle style) {
    final l10n = context.l10n;
    return switch (style) {
      MapStyle.openStreetMap => l10n.settings_appearance_mapStyle_openStreetMap,
      MapStyle.openTopoMap => l10n.settings_appearance_mapStyle_openTopoMap,
      MapStyle.esriSatellite => l10n.settings_appearance_mapStyle_esriSatellite,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final current = ref.watch(settingsProvider.select((s) => s.mapStyle));

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      child: PopupMenuButton<MapStyle>(
        tooltip: context.l10n.settings_appearance_mapStyle,
        initialValue: current,
        onSelected: (style) =>
            ref.read(settingsProvider.notifier).setMapStyle(style),
        itemBuilder: (context) => [
          for (final style in MapStyle.values)
            CheckedPopupMenuItem<MapStyle>(
              value: style,
              checked: style == current,
              child: Text(_label(context, style)),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.layers_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
