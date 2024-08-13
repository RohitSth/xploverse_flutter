import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_xploverse/features/map/domain/use_case/route_api.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/features/event/presentation/view/event_screen.dart';
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

  String? userProfilePictureUrl;

  List<LatLng> _routePoints = [];

  List<LatLng> eventLatLngs = [];
  Map<LatLng, String> eventNames =
      {}; // Map to store event names by their location
  List<Map<String, dynamic>> nearbyEvents = []; //For List of nearby events

  StreamSubscription<QuerySnapshot>? eventSubscription;

  final Map<String, TileLayer> layers = {
    'Default': TileLayer(
      urlTemplate:
          "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.example.xploverse',
      tileProvider: NetworkTileProvider(),
      maxZoom: 20,
      maxNativeZoom: 18,
      keepBuffer: 10,
    ),
    'OpenStreetMap': TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.xploverse',
      tileProvider: NetworkTileProvider(),
      maxZoom: 20,
      maxNativeZoom: 18,
      keepBuffer: 10,
    ),
    'Esri World Imagery': TileLayer(
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.example.xploverse',
      tileProvider: NetworkTileProvider(),
      maxZoom: 20,
      maxNativeZoom: 18,
      keepBuffer: 10,
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

    const double maxDistance = 10.0; // Maximum distance in kilometers

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
    currentLayer = 'Default';
    _getCurrentLocation();
    _listenToEventLocations(); // Set up real-time listener for event locations
    _getUserProfilePicture();
  }

  Future<void> _getUserProfilePicture() async {
    final User? user = FirebaseAuth.instance.currentUser;
    print('Current user: ${user?.uid}');
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print('User data: ${userData.data()}');
        setState(() {
          userProfilePictureUrl =
              userData.data()?['profilePictureUrl'] ?? user.photoURL;
        });
        print('User profile picture URL: $userProfilePictureUrl');
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
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
    _calculateNearbyEvents();
  }

  void _listenToEventLocations() {
    eventSubscription = FirebaseFirestore.instance
        .collection('events')
        .orderBy('startDate', descending: true)
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {
      List<LatLng> latLngList = [];
      Map<LatLng, String> nameMap = {};

      for (var doc in querySnapshot.docs) {
        double? latitude = doc['latitude'];
        double? longitude = doc['longitude'];
        String? title = doc['title'];
        String? endDateString = doc['endDate'];

        if (latitude != null && longitude != null && endDateString != null) {
          DateTime endDate = DateTime.parse(endDateString);

          // Only include events that haven't ended yet
          if (endDate.isAfter(DateTime.now())) {
            LatLng latLng = LatLng(latitude, longitude);
            latLngList.add(latLng);
            if (title != null) {
              nameMap[latLng] = title;
            }
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

  void _showEventPopup(LatLng eventLatLng) async {
    // Fetch event details from Firestore
    final QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('latitude', isEqualTo: eventLatLng.latitude)
        .where('longitude', isEqualTo: eventLatLng.longitude)
        .limit(1)
        .get();

    if (eventSnapshot.docs.isNotEmpty) {
      final eventDoc = eventSnapshot.docs.first;
      final eventData = eventDoc.data() as Map<String, dynamic>;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(eventData['title'] ?? 'Event Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Description: ${eventData['description'] ?? 'N/A'}'),
                  Text(
                    'Date: ${_formatDate(eventData['startDate'])} - ${_formatDate(eventData['endDate'])}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: \$${eventData['ticketPrice'] ?? 'N/A'}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eventData['description'] ?? '',
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(eventData['organizerId'])
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                            'Organizer information not available');
                      }

                      Map<String, dynamic> organizerData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Organizer:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Organization: ${organizerData['organization'] ?? 'N/A'}',
                          ),
                          Text(
                            'Phone: ${organizerData['phone'] ?? 'N/A'}',
                          ),
                        ],
                      );
                    },
                  ),
                  // Add more event details as needed
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      print('Event not found');
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
        // Trigger route recalculation when user location changes
        _recalculateRoute();
        _calculateNearbyEvents();
      });
    });
  }

  // Method to calculate distance between user and event
  double _calculateDistance(LatLng eventLatLng) {
    if (userLocation == null)
      return 0.0; // Handle cases where user location is unavailable

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
      tileProvider: NetworkTileProvider(),
      maxZoom: 20,
      maxNativeZoom: 18,
      keepBuffer: 10,
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
                      width: 50,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color.fromARGB(136, 0, 204, 255),
                                  width: 2),
                            ),
                            child: ClipOval(
                              child: userProfilePictureUrl != null &&
                                      userProfilePictureUrl!.isNotEmpty
                                  ? Image.network(
                                      userProfilePictureUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Error loading image: $error');
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
                                  _showEventPopup(eventLatLng);
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
                              'Nearby Events',
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
                                _showEventPopup(event['latLng']);
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