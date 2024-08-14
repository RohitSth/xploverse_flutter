import 'package:flutter_xploverse/features/map/presentation/widget/event_location.dart';
import 'package:latlong2/latlong.dart';

void listenToEventLocations(
    Function(List<LatLng>, Map<LatLng, String>) onUpdate) {
  EventLocation.listenToEventLocations((latLngList, nameMap) {
    onUpdate(latLngList, nameMap);
  });
}
