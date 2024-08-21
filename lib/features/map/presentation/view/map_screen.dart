import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_xploverse/features/map/domain/use_case/route_api.dart';
import 'package:flutter_xploverse/features/map/presentation/navigator/event_location_listener.dart';
import 'package:flutter_xploverse/features/map/presentation/widget/beam_painter.dart';
import 'package:flutter_xploverse/features/map/presentation/widget/compass_icon.dart';
import 'package:flutter_xploverse/features/map/presentation/widget/event_search.dart';
import 'package:flutter_xploverse/features/map/presentation/widget/show_event_pop_up.dart';
import 'package:flutter_xploverse/features/map/presentation/widget/user_profile_picture.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final mapController = MapController();
  late String currentLayer;
  LatLng? userLocation;
  bool _showEventsScreen = false;
  bool _showCancelRouteButton = false;
  LatLng? _selectedEventLatLng;

  bool _isMounted = false;
  StreamSubscription<void>? _eventSubscription;

  double _direction = 0;

  String? userProfilePictureUrl;

  List<LatLng> _routePoints = [];

  List<LatLng> eventLatLngs = [];
  Map<LatLng, String> eventNames =
      {}; // Map to store event names by their location
  List<Map<String, dynamic>> nearbyEvents = []; //For List of nearby events

  final Map<String, TileLayer> layers = {
    'Default': TileLayer(
      urlTemplate:
          "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.example.xploverse',
    ),
    'OpenStreetMap': TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.xploverse',
    ),
    'Esri World Imagery': TileLayer(
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.example.xploverse',
    ),
  };

  List listOfPoints = [];
  List<LatLng> routePoints = [];

  Future<void> _getRoute(LatLng eventLatLng) async {
    if (userLocation == null) return; // Ensure userLocation is available

    try {
      final String userCoords =
          '${userLocation!.longitude},${userLocation!.latitude}';
      final String eventCoords =
          '${eventLatLng.longitude},${eventLatLng.latitude}';

      final response = await http.get(getRouteUrl(userCoords, eventCoords));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates =
            data['features'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
          _showCancelRouteButton = true; // Show the cancel route button
        });
      } else {
        print('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void _recalculateRoute() {
    if (_selectedEventLatLng != null) {
      _getRoute(_selectedEventLatLng!);
    }
  }

  // Method to calculate nearby events
  void _calculateNearbyEvents() {
    if (userLocation == null) return;

    const double maxDistance = 30.0; // Maximum distance in kilometers

    nearbyEvents = eventLatLngs.where((eventLatLng) {
      double distance = Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation!.longitude,
            eventLatLng.latitude,
            eventLatLng.longitude,
          ) /
          1000; // Convert meters to kilometers

      return distance <= maxDistance;
    }).map((eventLatLng) {
      return {
        'latLng': eventLatLng,
        'name': eventNames[eventLatLng] ?? 'Unknown Event',
      };
    }).toList();

    setState(() {}); // Trigger a rebuild to show the updated nearby events
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    currentLayer = 'Default';
    _getCurrentLocation();
    _eventSubscription = listenToEventLocations((latLngList, nameMap) {
      if (_isMounted) {
        setState(() {
          eventLatLngs = latLngList;
          eventNames = nameMap;
          _calculateNearbyEvents();
        });
      }
    });
    _getUserProfilePicture();
    FlutterCompass.events?.listen((CompassEvent event) {
      if (_isMounted) {
        setState(() {
          _direction = event.heading ?? 0;
        });
      }
    });
  }

  Future<void> _getUserProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? photoURL;
      if (user.photoURL != null) {
        // User has a profile picture from Google
        photoURL = user.photoURL;
      } else {
        // Fetch from your own database if needed
        photoURL = await getUserProfilePictureUrl();
      }
      if (mounted) {
        setState(() {
          userProfilePictureUrl = photoURL;
        });
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _eventSubscription?.cancel(); // Cancel subscription to avoid memory leaks
    super.dispose();
  }

  String locationMessage = "Waiting for location...";

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        locationMessage = "Access Provided";
      });
      _moveToCurrentLocation();
      _liveLocation();
      _calculateNearbyEvents(); // Add this line
    } catch (e) {
      setState(() {
        locationMessage = "Error getting location: $e";
      });
    }
  }

  void _liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    if (_isMounted) {
      setState(() {
        locationMessage = 'Live location active';
      });
    }

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (_isMounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          locationMessage =
              'Live location active: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _recalculateRoute();
          _calculateNearbyEvents();
        });
      }
    });
  }

  // Method to calculate distance between user and event
  double _calculateDistance(LatLng eventLatLng) {
    if (userLocation == null) {
      return 0.0; // Handle cases where user location is unavailable
    }

    return Geolocator.distanceBetween(
          userLocation!.latitude,
          userLocation!.longitude,
          eventLatLng.latitude,
          eventLatLng.longitude,
        ) /
        1000; // Convert meters to kilometers
  }

  void _moveToCurrentLocation() {
    if (userLocation != null) {
      mapController.move(userLocation!, 15.0);
    }
  }

  void _handleEventsPopUp() {
    setState(() {
      _showEventsScreen = !_showEventsScreen;
    });
  }

  void _hideEventsPopUp() {
    setState(() {
      _showEventsScreen = false;
    });
  }

  Future<void> _search(String query) async {
    final searchResultLocation = await searchEventLocation(query);
    if (searchResultLocation != null) {
      mapController.move(searchResultLocation, 15.0);
    } else {
      print('No events found with the given title.');
    }
  }

  void _cancelRoute() {
    setState(() {
      _routePoints.clear();
      _showCancelRouteButton = false; // Hide the cancel route button
      _selectedEventLatLng = null; // Clear the selected event
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    layers['Default'] = TileLayer(
      urlTemplate: isDarkMode
          ? "https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png"
          : "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.example.xploverse',
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(40.7128, -74.0060), // New York City
              initialZoom: 15.0, // Limit zoom out
              minZoom: 9.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              layers[currentLayer]!,
              CircleLayer(
                circles: [
                  if (userLocation != null)
                    CircleMarker(
                      point: userLocation!,
                      radius: 50, // Adjust this value to change the circle size
                      color: Colors.blue.withOpacity(0.2),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Beam of Light
                          CustomPaint(
                            size: const Size(25, 25),
                            painter: BeamPainter(direction: _direction),
                          ),
                          // User profile picture
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: userProfilePictureUrl != null &&
                                      userProfilePictureUrl!.isNotEmpty
                                  ? Image.network(
                                      userProfilePictureUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 20);
                                      },
                                    )
                                  : const Icon(Icons.person, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...eventLatLngs.map(
                    (eventLatLng) => Marker(
                      point: eventLatLng,
                      width: 150,
                      height: 120,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEventLatLng = eventLatLng;
                          });
                          _getRoute(eventLatLng);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                eventNames[eventLatLng] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                            if (_selectedEventLatLng == eventLatLng)
                              ElevatedButton(
                                onPressed: () {
                                  showEventPopup(context, eventLatLng);
                                },
                                child: const Text('View More'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
          // Search Bar
          Positioned(
            top: 35,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black
                      : const Color.fromARGB(104, 74, 145, 226),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search events...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    _search(value);
                  },
                ),
              ),
            ),
          ),

          // EventsScreen Container
          if (_showEventsScreen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width * 0.5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nearby Events (30KM Radius)',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _hideEventsPopUp,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: nearbyEvents.length,
                          itemBuilder: (context, index) {
                            final event = nearbyEvents[index];
                            final eventLatLng = event['latLng'] as LatLng;

                            // Calculate the distance here
                            final distance = _calculateDistance(eventLatLng);
                            return ListTile(
                              title: Text(
                                '${event['name']} (${distance.toStringAsFixed(1)} km)',
                              ),
                              onTap: () {
                                _getRoute(eventLatLng);
                                showEventPopup(context, eventLatLng);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Cancel Route Button
          Positioned(
            bottom: 228.0,
            right: 10.0,
            child: Visibility(
              // Hide when EventsScreen is visible
              visible: !_showEventsScreen,
              child: Column(
                children: [
                  if (_showCancelRouteButton)
                    FloatingActionButton(
                      onPressed: _cancelRoute,
                      backgroundColor: isDarkMode
                          ? const Color.fromARGB(100, 10, 123, 158)
                          : const Color.fromARGB(98, 105, 219, 253),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Layers
          Positioned(
            bottom: 96,
            left: 10,
            child: Visibility(
              // Hide when EventsScreen is visible
              visible: !_showEventsScreen,
              child: FloatingActionButton(
                backgroundColor: isDarkMode
                    ? const Color.fromARGB(100, 10, 123, 158)
                    : const Color.fromARGB(98, 105, 219, 253),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Layer'),
                      children: layers.keys.map((String choice) {
                        return SimpleDialogOption(
                          onPressed: () {
                            setState(() {
                              currentLayer = choice;
                            });
                            Navigator.pop(context);
                          },
                          child: Text(choice),
                        );
                      }).toList(),
                    ),
                  );
                },
                child: const Icon(Icons.layers),
              ),
            ),
          ),
          // Compass
          Positioned(
            top: 100,
            right: 10,
            child: CompassIcon(
              direction: _direction ?? 0,
              isDarkMode: isDarkMode,
            ),
          ),

          // Live location info
          Positioned(
            top: 90,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black54 : Colors.white70,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (locationMessage.startsWith('Live location active'))
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                  Text(
                    locationMessage,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Current Location
          Positioned(
            bottom: 96,
            right: 10,
            child: Visibility(
              // Hide when EventsScreen is visible
              visible: !_showEventsScreen,
              child: FloatingActionButton(
                backgroundColor: isDarkMode
                    ? const Color.fromARGB(100, 10, 123, 158)
                    : const Color.fromARGB(98, 105, 219, 253),
                onPressed: _moveToCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
          // Show Events
          // Add a floating action button to show the EventsScreen
          Positioned(
            bottom: 162,
            right: 10,
            child: Visibility(
              // Hide when EventsScreen is visible
              visible: !_showEventsScreen,
              child: FloatingActionButton(
                backgroundColor: isDarkMode
                    ? const Color.fromARGB(100, 10, 123, 158)
                    : const Color.fromARGB(98, 105, 219, 253),
                onPressed: _handleEventsPopUp,
                child: const Icon(Icons.event),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.parse(dateString);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
