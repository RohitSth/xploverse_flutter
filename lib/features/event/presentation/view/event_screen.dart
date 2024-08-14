import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class EventsScreen extends ConsumerWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPCOMMING EVENTS'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget('Error fetching events');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs;
          final filteredEvents = _filterEvents(events);

          if (filteredEvents.isEmpty) {
            return _buildErrorWidget('No upcoming events found');
          }

          return ListView.builder(
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final eventData =
                  filteredEvents[index].data() as Map<String, dynamic>;
              final eventId = filteredEvents[index].id;

              return _buildEventCard(context, eventData, eventId, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterEvents(
      List<QueryDocumentSnapshot> events) {
    return events.where((event) {
      final eventData = event.data() as Map<String, dynamic>;
      final endDate = DateTime.parse(eventData['endDate']);
      return endDate.isAfter(DateTime.now());
    }).toList();
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> eventData,
      String eventId, bool isDarkMode) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _showEventDetailsPopup(context, eventData, eventId, isDarkMode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            if (eventData['images'] != null && eventData['images'].isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  eventData['images'][0],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.calendar_today,
                      _formatDateRange(
                          eventData['startDate'], eventData['endDate'])),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.location_on, eventData['address'] ?? ''),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.attach_money,
                      '${eventData['ticketPrice'] ?? 'N/A'}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEventDetailsPopup(
                        context, eventData, eventId, isDarkMode),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _bookEvent(context, eventId, eventData),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetailsPopup(BuildContext context,
      Map<String, dynamic> eventData, String eventId, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child:
                          const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  eventData['title'] ?? 'OKAEEE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  eventData['subtitle'] ?? 'Nicee',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                    Icons.location_on, eventData['address'] ?? 'KTMsdljh'),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.calendar_today,
                    _formatDateRange(
                        eventData['startDate'], eventData['endDate'])),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.attach_money, '${eventData['ticketPrice'] ?? '2.0'}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.people,
                    '${eventData['maxParticipants'] ?? '20'} MAX'),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.description, eventData['description'] ?? 'TEST'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, eventData['phone'] ?? '9898989822'),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        _bookEvent(context, eventId, eventData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Event booked successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to book event: $e')),
                        );
                      } finally {
                        Navigator.of(context)
                            .pop(); // Close the popup regardless of success/failure
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Book',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(date.toDate());
    }
    return date.toString();
  }

  void _bookEvent(BuildContext context, String eventId,
      Map<String, dynamic> eventData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(context, 'Please log in to book an event');
      return;
    }

    final maxParticipants = eventData['maxParticipants'] ?? 0;
    final bookingCount = await _getBookingCount(eventId);

    if (bookingCount >= maxParticipants) {
      _showSnackBar(context, 'Event is fully booked');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'eventId': eventId,
        'eventTitle': eventData['title'],
        'eventDate': eventData['startDate'],
        'bookingDate': FieldValue.serverTimestamp(),
      });
      _showSnackBar(context, 'Event booked successfully');
    } catch (e) {
      _showSnackBar(context, 'Error booking event: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<int> _getBookingCount(String eventId) async {
    final bookingCountSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('eventId', isEqualTo: eventId)
        .get();
    return bookingCountSnapshot.docs.length;
  }

  String _formatDateRange(String? startDateString, String? endDateString) {
    if (startDateString == null || endDateString == null) return '';
    final startDate = DateTime.parse(startDateString);
    final endDate = DateTime.parse(endDateString);
    final formatter = DateFormat('MMM d, y');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }
}
