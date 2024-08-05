import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = MapController();
  late String currentLayer;

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
  }

  // ------------------LOCATION------------------------------
  String locationMessage = "Current location";
  late String lat;
  late String long;

  // Get Current Location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are permanently denied, we cannot request permission");
    }

    return await Geolocator.getCurrentPosition();
  }

  // Listen to location updates
  void _liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 100,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      lat = position.latitude.toString();
      long = position.longitude.toString();

      setState(() {
        locationMessage = 'Latitude: $lat, Longitude: $long';
      });
    });
  }

  // ------------------LOCATION------------------------------

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
                  initialZoom: 10.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  layers[currentLayer]!,
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(40.7128, -74.0060),
                        width: 80,
                        height: 80,
                        child: Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                // Add a PopupMenuButton to change the layer
                bottom: 100,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      getLayerIcon(currentLayer),
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onSelected: (String value) {
                      setState(() {
                        currentLayer = value;
                      });
                    },
                    offset: const Offset(0, -170), // Position above the button
                    itemBuilder: (BuildContext context) {
                      return layers.keys.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Row(
                            children: [
                              Icon(
                                getLayerIcon(choice),
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                choice,
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              Positioned(top: 10, right: 10, child: Text(locationMessage)),
              Positioned(
                  bottom: 160,
                  right: 10,
                  child: ElevatedButton(
                    onPressed: () {
                      _getCurrentLocation().then((value) {
                        lat = '${value.latitude}';
                        long = '${value.longitude}';
                        setState(() {
                          locationMessage = 'Lat: $lat, Long: $long';
                        });
                        _liveLocation();
                      });
                    },
                    child: const Icon(Icons.my_location),
                  )),
              // Positioned(
              //   bottom: 10,
              //   right: 10,
              //   child: Container(
              //     padding: const EdgeInsets.all(4),
              //     color: isDarkMode ? Colors.black54 : Colors.white54,
              //     child: Text(
              //       getAttribution(),
              //       style: TextStyle(
              //         color: isDarkMode ? Colors.white70 : Colors.black54,
              //         fontSize: 10,
              //       ),
              //     ),
              //   ),
              // ),
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
