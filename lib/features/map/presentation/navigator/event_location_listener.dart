import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:flutter_xploverse/features/map/presentation/widget/event_location.dart';

StreamSubscription<void> listenToEventLocations(
    Function(List<LatLng>, Map<LatLng, String>) onUpdate) {
  return EventLocation.listenToEventLocations((latLngList, nameMap) {
    onUpdate(latLngList, nameMap);
  });
}
