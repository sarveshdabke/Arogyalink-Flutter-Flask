// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';

class HospitalMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String hospitalName;

  const HospitalMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hospitalName,
  });

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController.withPosition(
      initPosition: GeoPoint(
        latitude: widget.latitude,
        longitude: widget.longitude,
      ),
    );

    // ✅ Call route after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drawRoute();
    });
  }

  Future<void> _drawRoute() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied");
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      GeoPoint userLocation =
          GeoPoint(latitude: position.latitude, longitude: position.longitude);

      GeoPoint hospitalLocation =
          GeoPoint(latitude: widget.latitude, longitude: widget.longitude);

      // ✅ Move to current location first
      await mapController.changeLocation(userLocation);

      // ✅ Draw exact road
      await mapController.drawRoad(
        userLocation,
        hospitalLocation,
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadColor: Colors.blue,
          roadWidth: 8,
        ),
      );
    } catch (e) {
      print("Error drawing route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hospitalName)),
      body: OSMFlutter(
        controller: mapController,
        osmOption: OSMOption(
          zoomOption: const ZoomOption(
            initZoom: 14,
            minZoomLevel: 8,
            maxZoomLevel: 19,
          ),
          staticPoints: [
            StaticPositionGeoPoint(
              "hospital",
              const MarkerIcon(
                icon: Icon(Icons.local_hospital, color: Colors.red, size: 48),
              ),
              [GeoPoint(latitude: widget.latitude, longitude: widget.longitude)],
            ),
          ],
        ),
      ),
    );
  }
}
