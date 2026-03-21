import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/StationDetailScreen.dart';

import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:provider/provider.dart';

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({super.key});

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  loc.LocationData? _currentLocation;
  final loc.Location _locationService = loc.Location();

  List<Map<String, dynamic>> _stations = [];
  final PageController _pageController = PageController(viewportFraction: 0.85);
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoading = true;
  int? _selectedStationId;
  String? _currentTravelTime;
  String? _currentTravelDistance;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getUserLocation();
    await _fetchStations();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    try {
      final locData = await _locationService.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation = locData;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2) / 1000.0;
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    final start = LatLng(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
    );
    final url =
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylineEncoded = route['geometry'];
          final List<LatLng> decodedPoints = _decodePolyline(polylineEncoded);

          // OSRM returns duration in seconds and distance in meters
          final double durationSeconds = (route['duration'] as num).toDouble();
          final double distanceMeters = (route['distance'] as num).toDouble();

          final int minutes = (durationSeconds / 60).round();
          final double km = distanceMeters / 1000.0;

          if (mounted) {
            final locale = Provider.of<SettingsProvider>(
              context,
              listen: false,
            ).locale;
            setState(() {
              _currentTravelTime = "$minutes ${'minutes'.tr(locale)}";
              _currentTravelDistance = "${km.toStringAsFixed(1)} km";
              _polylines = [
                Polyline(
                  points: decodedPoints,
                  strokeWidth: 5.0,
                  color: const Color(0xFF1B4F72),
                  borderColor: Colors.white,
                  borderStrokeWidth: 2.0,
                ),
              ];
            });

            // Sky View Animation: Fit the route into view
            _fitRouteBounds(decodedPoints);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    // Calculate bounds
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      // Animate to fit bounds with padding
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 150),
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fetchStations() async {
    try {
      final data = await supabase.from('stations').select();
      final List<Map<String, dynamic>> fetchedStations =
          List<Map<String, dynamic>>.from(data);

      LatLng? userLatLng;
      if (_currentLocation != null) {
        userLatLng = LatLng(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        );
      }

      // Calculate distance and store
      for (var s in fetchedStations) {
        if (s['lat'] != null && s['lng'] != null && userLatLng != null) {
          s['distance'] = _calculateDistance(
            userLatLng,
            LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
          );
        } else {
          s['distance'] = double.infinity;
        }
      }

      // Sort by distance
      fetchedStations.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      List<Marker> markers = [];
      if (userLatLng != null) {
        // Add User Location Marker
        markers.add(
          Marker(
            point: userLatLng,
            width: 30,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      for (int i = 0; i < fetchedStations.length; i++) {
        final station = fetchedStations[i];
        final latRaw = station['lat'];
        final lngRaw = station['lng'];

        if (latRaw != null && lngRaw != null) {
          final lat = (latRaw as num).toDouble();
          final lng = (lngRaw as num).toDouble();
          final stationLatLng = LatLng(lat, lng);
          final bool isSelected = _selectedStationId == station['id'];
          final String? imageUrl = station['image_url'];
          final String distanceStr =
              (station['distance'] != null &&
                  station['distance'] != double.infinity)
              ? " (${(station['distance'] as double).toStringAsFixed(1)} km)"
              : "";

          markers.add(
            Marker(
              point: stationLatLng,
              width: isSelected ? 140 : 120,
              height: isSelected ? 110 : 90,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => _selectStation(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Station Name & Distance Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${station['name'] ?? ''}$distanceStr",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Station Image/Logo in a Circle
                    Container(
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 50 : 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B4F72)
                              : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Icon(
                              Icons.local_gas_station,
                              color: isSelected
                                  ? const Color(0xFF1B4F72)
                                  : Colors.grey,
                              size: isSelected ? 24 : 20,
                            )
                          : null,
                    ),
                    // Pointer arrow
                    Icon(
                      Icons.arrow_drop_down,
                      color: isSelected
                          ? const Color(0xFF1B4F72)
                          : Colors.white,
                      size: isSelected ? 24 : 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _stations = fetchedStations;
        _markers = markers;
        _isLoading = false;
      });

      // Auto-route to nearest if stations exist
      if (_stations.isNotEmpty &&
          _stations.first['distance'] != double.infinity) {
        _selectStation(0, moveMap: true);
      }
    } catch (e) {
      debugPrint("Error fetching stations for map: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _selectStation(
    int index, {
    bool moveMap = true,
    bool scrollCarousel = true,
  }) {
    if (index < 0 || index >= _stations.length) return;
    final station = _stations[index];
    final lat = (station['lat'] as num).toDouble();
    final lng = (station['lng'] as num).toDouble();
    final stationLatLng = LatLng(lat, lng);

    setState(() {
      _selectedStationId = station['id'];
    });

    _fetchRoute(stationLatLng);

    if (moveMap) {
      _mapController.move(stationLatLng, 14.5);
    }

    if (scrollCarousel && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // Refresh markers to show selection color
    _updateMarkers();
  }

  void _updateMarkers() {
    // This is a simple way to update marker colors without re-fetching
    // In a more complex app, you might want to use a ValueNotifier for each marker
    List<Marker> markers = [];

    // Add User Location Marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < _stations.length; i++) {
      final station = _stations[i];
      final lat = (station['lat'] as num).toDouble();
      final lng = (station['lng'] as num).toDouble();
      final stationLatLng = LatLng(lat, lng);
      final bool isSelected = _selectedStationId == station['id'];
      final String? imageUrl = station['image_url'];
      final String distanceStr =
          (station['distance'] != null &&
              station['distance'] != double.infinity)
          ? " (${(station['distance'] as double).toStringAsFixed(1)} km)"
          : "";

      markers.add(
        Marker(
          point: stationLatLng,
          width: isSelected ? 140 : 120,
          height: isSelected ? 110 : 90,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _selectStation(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Station Name Label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${station['name'] ?? ''}$distanceStr",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // Station Image/Logo in a Circle
                Container(
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 50 : 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1B4F72)
                          : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: imageUrl != null && imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? Icon(
                          Icons.local_gas_station,
                          color: isSelected
                              ? const Color(0xFF1B4F72)
                              : Colors.grey,
                          size: isSelected ? 24 : 20,
                        )
                      : null,
                ),
                // Pointer arrow
                Icon(
                  Icons.arrow_drop_down,
                  color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
                  size: isSelected ? 24 : 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale;

    return Scaffold(
      appBar: AppBar(title: Text("near_me".tr(locale))),
      body: _isLoading
          ? Center(child: MoonSunLoading())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        (_currentLocation?.latitude != null &&
                            _currentLocation?.longitude != null)
                        ? LatLng(
                            _currentLocation!.latitude!,
                            _currentLocation!.longitude!,
                          )
                        : const LatLng(16.8409, 96.1735),
                    initialZoom: 13,
                    onTap: (_, _) {
                      setState(() {
                        _selectedStationId = null;
                        _polylines = [];
                        _currentTravelTime = null;
                        _currentTravelDistance = null;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.msloyalty',
                    ),
                    PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Info Overlay for Route
                if (_currentTravelTime != null)
                  Positioned(
                    top: 80,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4F72).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${'duration'.tr(locale)} - $_currentTravelTime",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: Colors.white24,
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.straighten,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentTravelDistance!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "estimation_warning".tr(locale),
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Carousel at the bottom
                if (_stations.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    height: 180,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _stations.length,
                      onPageChanged: (index) {
                        _selectStation(
                          index,
                          moveMap: true,
                          scrollCarousel: false,
                        );
                      },
                      itemBuilder: (context, index) {
                        final station = _stations[index];
                        return _buildStationCard(station, index);
                      },
                    ),
                  ),

                if (_stations.isEmpty && !_isLoading)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "no_station_data".tr(locale),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                // Re-center FAB
                Positioned(
                  top: 20,
                  right: 20,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      if (_currentLocation != null) {
                        _mapController.move(
                          LatLng(
                            _currentLocation!.latitude!,
                            _currentLocation!.longitude!,
                          ),
                          15,
                        );
                      }
                    },
                    backgroundColor: const Color(0xFF1B4F72),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStationCard(Map<String, dynamic> station, int index) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final locale = settings.locale;
    final bool isSelected = _selectedStationId == station['id'];
    final String? imageUrl = station['image_url'];
    final double distance = station['distance'] as double;

    return GestureDetector(
      onTap: () => _selectStation(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: 10,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: const Color(0xFF1B4F72), width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Image Section
            Container(
              width: 120,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Center(
                      child: Icon(
                        Icons.local_gas_station,
                        color: Colors.grey,
                        size: 40,
                      ),
                    )
                  : null,
            ),

            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      station['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station['address'] ?? 'No address',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4F72).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isSelected && _currentTravelTime != null
                                ? _currentTravelTime!
                                : (distance == double.infinity
                                      ? "---"
                                      : "${distance.toStringAsFixed(1)} km ${'away'.tr(locale)}"),
                            style: const TextStyle(
                              color: Color(0xFF1B4F72),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StationDetailScreen(station: station),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4F72),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B4F72).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "show_detail".tr(locale),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
