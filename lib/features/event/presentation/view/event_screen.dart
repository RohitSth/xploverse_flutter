import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPCOMING EVENTS'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two events per row
                    crossAxisSpacing: 8.0, // Space between columns
                    mainAxisSpacing: 8.0, // Space between rows
                    childAspectRatio: 0.75, // Adjust the height/width ratio
                  ),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final eventData =
                        filteredEvents[index].data() as Map<String, dynamic>;
                    final eventId = filteredEvents[index].id;

                    return _buildEventCard(
                        context, eventData, eventId, isDarkMode);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 100), // Add a 100px gap here
        ],
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
            style: const TextStyle(fontSize: 18, color: Colors.white),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _showEventDetailsPopup(context, eventData, eventId, isDarkMode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eventData['images'] != null && eventData['images'].isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  eventData['images'][0],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                      Icons.calendar_today,
                      _formatDateRange(
                          eventData['startDate'], eventData['endDate']),
                      isDarkMode),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.location_on, eventData['address'] ?? '',
                      isDarkMode),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.attach_money,
                      '${eventData['ticketPrice'] ?? 'N/A'}', isDarkMode),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showBookingDialog(context, eventId, eventData),
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

  void _showBookingDialog(
      BuildContext context, String eventId, Map<String, dynamic> eventData) {
    int ticketQuantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Book Event: ${eventData['title']}'),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _bookEvent(context, eventId, eventData, ticketQuantity);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Book'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEventDetailsPopup(BuildContext context,
      Map<String, dynamic> eventData, String eventId, bool isDarkMode) {
    int ticketQuantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      eventData['title'] ?? '',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eventData['subtitle'] ?? '',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.location_on, eventData['address'] ?? '',
                        isDarkMode),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.calendar_today,
                        _formatDateRange(
                            eventData['startDate'], eventData['endDate']),
                        isDarkMode),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.attach_money,
                        '${eventData['ticketPrice'] ?? ''}', isDarkMode),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.people,
                        '${eventData['maxParticipants'] ?? ''} MAX',
                        isDarkMode),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.description,
                        eventData['description'] ?? '', isDarkMode),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.phone, eventData['contact'] ?? '', isDarkMode),
                    const SizedBox(height: 16),
                    if (eventData['images'] != null &&
                        eventData['images'].isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          eventData['images'][0],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _showBookingDialog(context, eventId, eventData);
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Book Event'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _bookEvent(BuildContext context, String eventId,
      Map<String, dynamic> eventData, int ticketQuantity) {
    // Handle the event booking logic here
    final user = FirebaseAuth.instance.currentUser;

    // Book the event and generate a ticket for the user
    final bookingData = {
      'userId': user?.uid,
      'eventId': eventId,
      'quantity': ticketQuantity,
      'bookingDate': DateTime.now().toString(),
      // Additional booking details...
    };

    FirebaseFirestore.instance.collection('bookings').add(bookingData);
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

  String _formatDateRange(String startDate, String endDate) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final DateTime start = DateTime.parse(startDate);
    final DateTime end = DateTime.parse(endDate);

    if (start.year == end.year && start.month == end.month) {
      return '${formatter.format(start)} - ${DateFormat('dd, yyyy').format(end)}';
    } else {
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }
  }
}
