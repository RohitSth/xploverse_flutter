import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = MapController();
  late String currentLayer;
  LatLng? userLocation;
  double _direction = 0;

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
    _startCompass();
  }

  // ------------------LOCATION------------------------------
  String locationMessage = "Waiting for location...";

  // Get Current Location
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

  // Listen to location updates
  void _liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    // Update message immediately when we start listening
    setState(() {
      locationMessage = 'Live location active';
    });

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        // Update message with each new position
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

  // ------------------LOCATION END-----------------------

  // ------------------COMPASS------------------------------
  StreamSubscription<CompassEvent>? _compassSubscription;

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _direction = event.heading ?? 0;
        });
        mapController.rotate(-_direction * (math.pi / 180));
      }
    });
  }

  @override
  void dispose() {
    debugPrint('Cancelling compass subscription...');
    _compassSubscription?.cancel();
    super.dispose();
  }

  // ------------------COMPASS END------------------------------

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Update the Default layer based on the theme
    layers['Default'] = TileLayer(
      urlTemplate: isDarkMode
          ? "https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png"
          : "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.example.xploverse',
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: LatLng(40.7128, -74.0060), // New York City
                  initialZoom: 15.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 100,
                right: 10,
                child: FloatingActionButton(
                  backgroundColor: const Color.fromARGB(100, 10, 123, 158),
                  onPressed: () {
                    // Show a simple dialog to select layers
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
              Positioned(
                top: 10,
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
              Positioned(
                bottom: 160,
                right: 10,
                child: FloatingActionButton(
                  backgroundColor: const Color.fromARGB(100, 10, 123, 158),
                  onPressed: _moveToCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData getLayerIcon(String layer) {
    switch (layer) {
      case 'Default':
        return Icons.map_outlined;
      case 'OpenStreetMap':
        return Icons.public;
      case 'Esri World Imagery':
        return Icons.photo_camera;
      default:
        return Icons.layers; // Default icon if layer is not recognized
    }
  }

  String getAttribution() {
    switch (currentLayer) {
      case 'Default':
        return '© OpenStreetMap contributors, © CARTO';
      case 'OpenStreetMap':
        return '© OpenStreetMap contributors';
      case 'Esri World Imagery':
        return 'Tiles © Esri';
      default:
        return '© OpenStreetMap contributors';
    }
  }
}
