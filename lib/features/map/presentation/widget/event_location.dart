import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EventLocation {
  static StreamSubscription<QuerySnapshot>? eventSubscription;

  static Future<void> listenToEventLocations(
      Function(List<LatLng>, Map<LatLng, String>) onEventsUpdated) async {
    eventSubscription?.cancel();

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

        if (latitude != null &&
            longitude != null &&
            endDateString != null &&
            title != null) {
          DateTime endDate = DateTime.parse(endDateString);

          // Only include events that haven't ended yet
          if (endDate.isAfter(DateTime.now())) {
            LatLng latLng = LatLng(latitude, longitude);
            latLngList.add(latLng);
            nameMap[latLng] = title;
          }
        }
      }
      onEventsUpdated(latLngList, nameMap);
    }, onError: (e) {
      print('Error listening to event locations: $e');
    });
  }
}
