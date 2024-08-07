import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/providers/events_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final mapController = MapController();
  late String currentLayer;
  LatLng? userLocation;

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final eventLatLngs = ref.watch(eventLatLngsProvider);

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
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
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
        return Icons.layers;
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
