import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

Future<LatLng?> searchEventLocation(String query) async {
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
        return LatLng(latitude, longitude);
      }
    }
  } catch (e) {
    print('Error during search: $e');
  }
  return null;
}
