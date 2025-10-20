// lib/screens/hospitals/nearby_hospitals.dart

// ignore_for_file: prefer_final_fields, use_build_context_synchronously, prefer_const_constructors, deprecated_member_use, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/screens/appointment/book_opd.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  final dynamic referralData;
  const NearbyHospitalsScreen({super.key, this.referralData});

  @override
  _NearbyHospitalsScreenState createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  GeoPoint? _userInitialPosition;
  MapController? _mapController;
  bool _isLoading = true;
  String _errorText = '';

  final List<GeoPoint> _hospitalMarkers = [];
  final Map<GeoPoint, Map<String, dynamic>> _hospitalMap = {};

  Map<String, dynamic>? _selectedHospital;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable them.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied. Please grant them.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        forceAndroidLocationManager: true,
      );

      _userInitialPosition = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _mapController?.dispose();
      _mapController = MapController(initPosition: _userInitialPosition);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _setError('Failed to get user location: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorText = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchAndDisplayRegisteredHospitals() async {
    final String? authToken = await _apiService.getToken();
    if (authToken == null) {
      _setError('Authentication token not found. Please log in.');
      return;
    }

    final result = await _apiService.fetchAllHospitals();
    if (result['success'] == true) {
      final List<dynamic> hospitals = result['data'];
      if (hospitals.isEmpty) {
        if (_hospitalMarkers.isNotEmpty) {
          await _mapController?.removeMarkers(_hospitalMarkers);
          _hospitalMarkers.clear();
        }
        _toggleHospitalCard(null);
        return;
      }
      await _addHospitalMarkers(hospitals);

      if (_hospitalMarkers.isNotEmpty) {
        _toggleHospitalCard(_hospitalMarkers.first);
        await _mapController?.goToLocation(_hospitalMarkers.first);
      }
    } else {
      _setError(result['message'] ?? 'Failed to load hospitals');
    }
  }

  Future<void> _addHospitalMarkers(List<dynamic> hospitals) async {
    if (_hospitalMarkers.isNotEmpty) {
      await _mapController?.removeMarkers(_hospitalMarkers);
      _hospitalMarkers.clear();
      _hospitalMap.clear();
    }

    if (_userInitialPosition != null) {
      await _mapController?.addMarker(
        _userInitialPosition!,
        markerIcon: MarkerIcon(
          icon: Icon(Icons.person_pin_circle, color: Colors.blue, size: 56),
        ),
      );
    }

    for (var hospital in hospitals) {
      try {
        final lat = double.parse(hospital['latitude'].toString());
        final lon = double.parse(hospital['longitude'].toString());
        final hospitalPoint = GeoPoint(latitude: lat, longitude: lon);

        await _mapController?.addMarker(
          hospitalPoint,
          markerIcon: MarkerIcon(
            icon: Icon(Icons.local_hospital, color: Colors.red, size: 48),
          ),
        );
        _hospitalMarkers.add(hospitalPoint);
        _hospitalMap[hospitalPoint] = hospital as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing hospital data: $e');
      }
    }
  }

  void _toggleHospitalCard(GeoPoint? point) {
    setState(() {
      if (point != null && _hospitalMap.containsKey(point)) {
        _selectedHospital = _hospitalMap[point];
      } else {
        _selectedHospital = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registered Hospitals')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    OSMFlutter(
                      controller: _mapController!,
                      onMapIsReady: (isReady) async {
                        if (isReady && _userInitialPosition != null) {
                          await _fetchAndDisplayRegisteredHospitals();
                        }
                      },
                      onGeoPointClicked: (GeoPoint point) {
                        _toggleHospitalCard(point);
                      },
                      osmOption: OSMOption(
                        userTrackingOption: const UserTrackingOption(
                          enableTracking: true,
                          unFollowUser: false,
                        ),
                        zoomOption: const ZoomOption(
                          initZoom: 14,
                          minZoomLevel: 3,
                          maxZoomLevel: 19,
                          stepZoom: 1.0,
                        ),
                        roadConfiguration: const RoadOption(roadColor: Colors.blue),
                      ),
                    ),

                    // ✅ Responsive hospital info card
                    if (_selectedHospital != null)
                      Positioned(
                        bottom: 20,
                        left: 16,
                        right: 16,
                        child: PointerInterceptor(
                          intercepting: true,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double cardWidth = constraints.maxWidth;
                              return Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: cardWidth < 400 ? cardWidth : 400,
                                  ),
                                  child: HospitalCard(hospital: _selectedHospital!),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  const HospitalCard({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    final dynamic opdAvailableValue = hospital['opd_available'];
    final bool isOpdAvailable = opdAvailableValue == true || opdAvailableValue == 1;

    return Container(
      width: double.infinity, // ✅ takes available width from parent
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital['hospital_name'] ?? 'Hospital Name Not Available',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hospital['address'] ?? 'No address provided',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hospital['emergency'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Emergency Available',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Text(
                "Beds: ${hospital['available_beds'] ?? 'N/A'}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isOpdAvailable)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookOPDScreen(
                            hospitalId: hospital['id'].toString(),
                            hospitalName: hospital['hospital_name'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_available, size: 20),
                    label: const Text("Book OPD"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This hospital does not provide OPD services.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
