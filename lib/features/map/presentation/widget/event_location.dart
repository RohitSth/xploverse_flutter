import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EventLocation {
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      listenToEventLocations(
          Function(List<LatLng>, Map<LatLng, String>) onEventsUpdated) {
    return FirebaseFirestore.instance
        .collection('events')
        .orderBy('startDate', descending: true)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      List<LatLng> latLngList = [];
      Map<LatLng, String> nameMap = {};

      for (var doc in querySnapshot.docs) {
        try {
          double? latitude = doc.data()?['latitude'];
          double? longitude = doc.data()?['longitude'];
          String? title = doc.data()?['title'];
          String? endDateString = doc.data()?['endDate'];

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
        } catch (e) {
          print('Error processing document: ${doc.id}, Error: $e');
        }
      }
      onEventsUpdated(latLngList, nameMap);
    }, onError: (e) {
      print('Error listening to event locations: $e');
    });
  }
}
