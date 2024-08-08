import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/features/event/presentation/view/events_screen.dart';
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

  List<LatLng> eventLatLngs = [];
  Map<LatLng, String> eventNames =
      {}; // Map to store event names by their location
  StreamSubscription<QuerySnapshot>? eventSubscription;

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

  @override
  void initState() {
    super.initState();
    currentLayer = 'Default';
    _getCurrentLocation();
    _listenToEventLocations(); // Set up real-time listener for event locations
  }

  @override
  void dispose() {
    eventSubscription?.cancel(); // Cancel subscription to avoid memory leaks
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
    } catch (e) {
      setState(() {
        locationMessage = "Error getting location: $e";
      });
    }
  }

  void _listenToEventLocations() {
    eventSubscription = FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {
      List<LatLng> latLngList = [];
      Map<LatLng, String> nameMap = {};

      for (var doc in querySnapshot.docs) {
        double? latitude = doc['latitude'];
        double? longitude = doc['longitude'];
        String? title = doc['title'];

        if (latitude != null && longitude != null) {
          LatLng latLng = LatLng(latitude, longitude);
          latLngList.add(latLng);
          if (title != null) {
            nameMap[latLng] = title;
          }
        }
      }

      setState(() {
        eventLatLngs = latLngList;
        eventNames = nameMap;
      });
    }, onError: (e) {
      print('Error listening to event locations: $e');
      setState(() {
        locationMessage = "Error fetching events: $e";
      });
    });
  }

  void _liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    setState(() {
      locationMessage = 'Live location active';
    });

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        locationMessage =
            'Live location active: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      _moveToCurrentLocation();
    });
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

  void _showEventsPopUp() {
    setState(() {
      _showEventsScreen = true;
    });
  }

  void _hideEventsPopUp() {
    setState(() {
      _showEventsScreen = false;
    });
  }

  Future<void> _search(String query) async {
    try {
      final QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('title', isEqualTo: query)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        final doc = eventSnapshot.docs.first;
        final double? latitude = doc['latitude'];
        final double? longitude = doc['longitude'];

        if (latitude != null && longitude != null) {
          // Instead of updating userLocation, directly move the map
          final searchResultLocation = LatLng(latitude, longitude);
          mapController.move(searchResultLocation, 15.0);
        } else {
          print('No events found with the given title.');
        }
      } else {
        print('No events found with the given title.');
      }
    } catch (e) {
      print('Error during search: $e');
    }
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
              initialZoom: 15.0,
              maxZoom: 30.0, // Limit zoom out
              minZoom: 5.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              layers[currentLayer]!,
              MarkerLayer(
                markers: [
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ...eventLatLngs.map(
                    (eventLatLng) => Marker(
                      point: eventLatLng,
                      width: 100,
                      height: 100,
                      child: SizedBox(
                        height: 120,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                eventNames[eventLatLng] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _showEventsPopUp,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Search Bar
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search for locations or events',
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
              bottom: 100,
              left: 0,
              right: 0,
              child: GestureDetector(
                child: Container(
                  height: MediaQuery.of(context).size.height *
                      0.5, // Half screen height
                  width: MediaQuery.of(context).size.width * 0.5,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  child: Column(
                    children: [
                      // Close button (Red Circle)
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: GestureDetector(
                              onTap: _hideEventsPopUp,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // EventsScreen content
                      const Expanded(
                        child: EventsScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Layers
          Positioned(
            bottom: 94,
            left: 10,
            child: Visibility(
              // Hide when EventsScreen is visible
              visible: !_showEventsScreen,
              child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(100, 10, 123, 158),
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
            bottom: 94,
            right: 10,
            child: Visibility(
              // Hide when EventsScreen is visible
              visible: !_showEventsScreen,
              child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(100, 10, 123, 158),
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
                backgroundColor: const Color.fromARGB(100, 10, 123, 158),
                onPressed: _handleEventsPopUp,
                child: const Icon(Icons.event),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
