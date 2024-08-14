import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

Future<void> showEventPopup(BuildContext context, LatLng eventLatLng) async {
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
                      return const Text('Organizer information not available');
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
    // ignore: avoid_print
    print('Event not found');
  }
}

String _formatDate(String? dateString) {
  if (dateString == null) return '';
  final date = DateTime.parse(dateString);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
