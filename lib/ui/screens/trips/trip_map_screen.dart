import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/extensions.dart';
import '../../../data/models/location_point.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/location_point_repository.dart';

class TripMapScreen extends StatefulWidget {
  final Trip trip;

  const TripMapScreen({super.key, required this.trip});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  // Future cachen, damit nicht bei jedem Rebuild neu abgefragt wird
  late final Future<List<LocationPoint>> _punkteFuture;

  Trip get trip => widget.trip;

  @override
  void initState() {
    super.initState();
    _punkteFuture = LocationPointRepository().fuerTrip(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fahrt ${trip.startTimestamp.datumFormatiert}'),
      ),
      body: FutureBuilder<List<LocationPoint>>(
        future: _punkteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final punkte = snapshot.data ?? [];

          if (punkte.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 64,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    const Text(
                      'Keine Streckendaten verfügbar',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.manuellErfasst
                          ? 'Manuell eingetragene Fahrten haben keine GPS-Daten.'
                          : 'Die GPS-Punkte dieser Fahrt wurden bereits gelöscht.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          final routePunkte = punkte
              .map((p) => LatLng(p.lat, p.lng))
              .toList();

          final bounds = LatLngBounds.fromPoints(routePunkte);
          // Bei (fast) identischen Punkten hat die Bounding-Box keine
          // Fläche — CameraFit.bounds würde dann ungültig zoomen.
          final hatFlaeche = (bounds.north - bounds.south).abs() > 0.0001 ||
              (bounds.east - bounds.west).abs() > 0.0001;

          return Column(
            children: [
              _infoLeiste(context, punkte),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: routePunkte.first,
                    initialZoom: 15,
                    initialCameraFit: hatFlaeche
                        ? CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(40),
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.oldtimer.km_log',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePunkte,
                          color: theme.colorScheme.primary,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePunkte.first,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.trip_origin,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                        Marker(
                          point: routePunkte.last,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoLeiste(BuildContext context, List<LocationPoint> punkte) {
    final theme = Theme.of(context);
    final dauer = trip.dauer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(
            context,
            Icons.route,
            trip.distanceKm.kmFormatiert,
            'Strecke',
          ),
          if (dauer != null)
            _infoItem(
              context,
              Icons.timer,
              dauer.dauerFormatiert,
              'Dauer',
            ),
          _infoItem(
            context,
            Icons.location_on,
            '${punkte.length}',
            'GPS-Punkte',
          ),
          if (trip.istFirmenfahrt)
            _infoItem(
              context,
              Icons.business,
              'Firma',
              'Fahrttyp',
            ),
        ],
      ),
    );
  }

  Widget _infoItem(
      BuildContext context, IconData icon, String wert, String label) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(wert, style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
