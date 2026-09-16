import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../geo_point.dart';
import '../map_widget_factory.dart';

/// Tile source settings. The OpenStreetMap Foundation's tile servers are for
/// light use with attribution and an identifying app name; a production
/// launch with real traffic should switch [urlTemplate] to a tile provider
/// with an SLA (MapTiler, Stadia, Thunderforest, self-hosted…) — the rest of
/// the app doesn't change.
class OsmTileConfig {
  final String urlTemplate;
  final String userAgentPackageName;
  final String attribution;
  final String attributionUrl;

  const OsmTileConfig({
    this.urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.userAgentPackageName = 'com.steamgallery.steam_gallery_app',
    this.attribution = 'OpenStreetMap contributors',
    this.attributionUrl = 'https://www.openstreetmap.org/copyright',
  });
}

/// OpenStreetMap implementation of [MapWidgetFactory] (flutter_map).
class OsmMapWidgetFactory implements MapWidgetFactory {
  final OsmTileConfig config;
  const OsmMapWidgetFactory({this.config = const OsmTileConfig()});

  @override
  Widget locationPicker({
    Key? key,
    required GeoPoint initialCenter,
    double initialZoom = MapZoom.street,
    required ValueChanged<GeoPoint> onCenterChanged,
    ValueChanged<GeoPoint>? onCenterSettled,
    List<MapCircle> circles = const [],
    ValueChanged<MapPickerController>? onControllerReady,
  }) => _OsmLocationPicker(
    key: key,
    config: config,
    initialCenter: initialCenter,
    initialZoom: initialZoom,
    onCenterChanged: onCenterChanged,
    onCenterSettled: onCenterSettled,
    circles: circles,
    onControllerReady: onControllerReady,
  );

  @override
  Widget preview({
    Key? key,
    required GeoPoint center,
    double zoom = MapZoom.street,
    GeoPoint? marker,
    List<MapCircle> circles = const [],
  }) => IgnorePointer(
    key: key,
    child: FlutterMap(
      options: MapOptions(
        initialCenter: _ll(center),
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        _tiles(config),
        _circleLayer(circles),
        if (marker != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _ll(marker),
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const _Pin(),
              ),
            ],
          ),
        _attribution(config),
      ],
    ),
  );
}

LatLng _ll(GeoPoint p) => LatLng(p.latitude, p.longitude);

Widget _tiles(OsmTileConfig config) => TileLayer(
  urlTemplate: config.urlTemplate,
  userAgentPackageName: config.userAgentPackageName,
);

Widget _circleLayer(List<MapCircle> circles) => CircleLayer(
  circles: [
    for (final c in circles)
      CircleMarker(
        point: _ll(c.center),
        radius: c.radiusKm * 1000,
        useRadiusInMeter: true,
        color: (c.emphasized ? AppColors.brandTeal : Colors.grey).withValues(
          alpha: 0.18,
        ),
        borderColor: c.emphasized ? AppColors.primaryDark : Colors.grey,
        borderStrokeWidth: 2,
      ),
  ],
);

// Required by the OSM tile usage policy: visible attribution with a link.
Widget _attribution(OsmTileConfig config) => RichAttributionWidget(
  attributions: [
    TextSourceAttribution(
      config.attribution,
      onTap: () => launchUrl(Uri.parse(config.attributionUrl)),
    ),
  ],
);

class _OsmLocationPicker extends StatefulWidget {
  final OsmTileConfig config;
  final GeoPoint initialCenter;
  final double initialZoom;
  final ValueChanged<GeoPoint> onCenterChanged;
  final ValueChanged<GeoPoint>? onCenterSettled;
  final List<MapCircle> circles;
  final ValueChanged<MapPickerController>? onControllerReady;

  const _OsmLocationPicker({
    super.key,
    required this.config,
    required this.initialCenter,
    required this.initialZoom,
    required this.onCenterChanged,
    required this.onCenterSettled,
    required this.circles,
    required this.onControllerReady,
  });

  @override
  State<_OsmLocationPicker> createState() => _OsmLocationPickerState();
}

class _OsmLocationPickerState extends State<_OsmLocationPicker>
    implements MapPickerController {
  final _controller = MapController();
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void moveTo(GeoPoint center, {double? zoom}) {
    _controller.move(_ll(center), zoom ?? _controller.camera.zoom);
    _onMoved(center);
  }

  void _onMoved(GeoPoint center) {
    widget.onCenterChanged(center);
    _settle?.cancel();
    _settle = Timer(
      const Duration(milliseconds: 600),
      () => widget.onCenterSettled?.call(center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _ll(widget.initialCenter),
            initialZoom: widget.initialZoom,
            // No rotation: a rotated map makes "which street is this" harder.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              widget.onControllerReady?.call(this);
              _onMoved(widget.initialCenter);
            },
            onPositionChanged: (camera, hasGesture) {
              final c = camera.center;
              _onMoved(GeoPoint(c.latitude, c.longitude));
            },
          ),
          children: [
            _tiles(widget.config),
            _circleLayer(widget.circles),
            _attribution(widget.config),
          ],
        ),
        // The pin is fixed to the centre of the map; its tip marks the point.
        const IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: SizedBox(width: 40, height: 40, child: _Pin()),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_on,
      size: 40,
      color: AppColors.brandGold,
      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
    );
  }
}
