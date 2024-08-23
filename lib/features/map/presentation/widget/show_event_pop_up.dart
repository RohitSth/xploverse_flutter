import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

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
    final eventId = eventDoc.id;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF212121), Color(0xFF000000)],
                            )
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Color(0xFF4A90E2)],
                            ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  eventData['title'] ?? 'Event Details',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (eventData['images'] != null &&
                            eventData['images'].isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: CarouselSlider(
                              options: CarouselOptions(
                                enableInfiniteScroll: false,
                                autoPlay: false,
                                enlargeCenterPage: true,
                                viewportFraction: 0.8,
                                aspectRatio: 16 / 9,
                                initialPage: 0,
                              ),
                              items: (eventData['images'] as List<dynamic>)
                                  .map((image) {
                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(image.toString()),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  eventData['description'] ?? '',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  _formatDateRange(
                                    eventData['startDate'],
                                    eventData['endDate'],
                                  ),
                                  isDarkMode,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.location_on,
                                  eventData['address'] ?? '',
                                  isDarkMode,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.attach_money,
                                  '${eventData['ticketPrice'] ?? ''}',
                                  isDarkMode,
                                ),
                                const SizedBox(height: 8),
                                // Display the number of tickets booked
                                FutureBuilder<int>(
                                  future: _getBookingCount(eventId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                        "Loading...",
                                        style: TextStyle(color: Colors.blue),
                                      );
                                    } else if (snapshot.hasError) {
                                      return const Text(
                                        "An error occured",
                                        style: TextStyle(color: Colors.red),
                                      );
                                    } else {
                                      final bookedCount = snapshot.data ?? 0;
                                      return _buildInfoRow(
                                        Icons.people,
                                        '${eventData['maxParticipants'] ?? ''} MAX | $bookedCount Booked',
                                        isDarkMode,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showBookingDialog(context, eventId, eventData);
                            },
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Book Event'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor:
                                  const Color.fromARGB(255, 15, 123, 247),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  } else {
    // ignore: avoid_print
    print('Event not found');
  }
}

Widget _buildInfoRow(IconData icon, String text, bool isDarkMode) {
  return Row(
    children: [
      Icon(icon, size: 16, color: isDarkMode ? Colors.white : Colors.black),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

String _formatDateRange(String? startDateString, String? endDateString) {
  if (startDateString == null || endDateString == null) return '';
  final startDate = DateTime.parse(startDateString);
  final endDate = DateTime.parse(endDateString);
  final formatter = DateFormat('MMM d, y');
  return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
}

void _showBookingDialog(
    BuildContext context, String eventId, Map<String, dynamic> eventData) {
  int ticketQuantity = 1;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text('${eventData['title']}')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select number of tickets:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (ticketQuantity > 1) ticketQuantity--;
                        });
                      },
                    ),
                    Text('$ticketQuantity'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          ticketQuantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  _bookEvent(context, eventId, eventData, ticketQuantity);
                },
                child: Text('Book $ticketQuantity Ticket(s)',
                    style: const TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
    },
  );
}

void _bookEvent(BuildContext context, String eventId,
    Map<String, dynamic> eventData, int ticketQuantity) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    _showSnackBar(context, 'Please log in to book an event');
    return;
  }

  final maxParticipants = eventData['maxParticipants'] ?? 0;
  final bookingCount = await _getBookingCount(eventId);

  if (bookingCount + ticketQuantity > maxParticipants) {
    _showSnackBar(context, 'Not enough tickets available');
    return;
  }

  try {
    for (int i = 0; i < ticketQuantity; i++) {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'eventId': eventId,
        'eventTitle': eventData['title'],
        'eventDate': eventData['startDate'],
        'bookingDate': FieldValue.serverTimestamp(),
      });
    }
    _showSnackBar(context,
        '$ticketQuantity ticket(s) booked successfully for ${eventData['title']}');
    Navigator.pop(context);
  } catch (e) {
    _showSnackBar(context, 'Error booking event: $e');
    Navigator.pop(context);
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        bottom: 96,
        right: 20,
        left: 20,
      ),
    ),
  );
}

Future<int> _getBookingCount(String eventId) async {
  final bookingCountSnapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('eventId', isEqualTo: eventId)
      .get();
  return bookingCountSnapshot.docs.length;
}
