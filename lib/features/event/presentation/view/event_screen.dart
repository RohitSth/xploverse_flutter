import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final List<String> categories = [
    'All',
    'Music',
    'Temple',
    'Nature',
    'Technology',
    'Travelling',
    'Anime',
    'Trekking',
    'Nature',
    'Adventure',
    'Business',
    'Cultural'
  ];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? const Color.fromARGB(255, 0, 0, 0)
              : const Color(0xFF4A90E2),
          title: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'UPCOMING EVENTS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color.fromARGB(255, 0, 0, 0),
                      const Color.fromARGB(255, 0, 38, 82),
                    ]
                  : [
                      const Color(0xFF4A90E2),
                      const Color.fromARGB(255, 0, 38, 82),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 30,
                left: 2,
                right: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = category == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDarkMode
                                      ? const Color(0xFF4A90E2)
                                      : const Color.fromARGB(255, 0, 0, 0))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: isSelected
                                    ? (isDarkMode
                                        ? const Color(0xFF4A90E2)
                                        : const Color.fromARGB(255, 0, 0, 0))
                                    : (isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  height: 400,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getEventsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No events found'),
                        );
                      }

                      final events = _filterEvents(snapshot.data!.docs);

                      if (events.isEmpty) {
                        return const Center(
                          child: Text(
                              'No upcoming events found for this category'),
                        );
                      }

                      return CarouselSlider.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index, realIndex) {
                          final eventData =
                              events[index].data() as Map<String, dynamic>;
                          final eventId = events[index].id;

                          return _buildEventCard(
                              context, eventData, eventId, isDarkMode);
                        },
                        options: CarouselOptions(
                          enlargeCenterPage: true,
                          height: 400,
                          autoPlay: true,
                          aspectRatio: 16 / 9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enableInfiniteScroll: false,
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 800),
                          viewportFraction: 0.8,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getEventsStream() {
    if (selectedCategory == 'All') {
      return FirebaseFirestore.instance
          .collection('events')
          .orderBy('startDate', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('events')
          .where('categories', arrayContains: selectedCategory)
          .snapshots();
    }
  }

  List<QueryDocumentSnapshot> _filterEvents(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    return docs.where((doc) {
      final eventData = doc.data() as Map<String, dynamic>;
      if (eventData['endDate'] == null) {
        return false;
      }
      final endDate = DateTime.parse(eventData['endDate']);
      return endDate.isAfter(now);
    }).toList();
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> eventData,
      String eventId, bool isDarkMode) {
    return GestureDetector(
      onTap: () =>
          _showEventDetailsPopup(context, eventData, eventId, isDarkMode),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                        colors: [Color(0xFF4A90E2), Colors.white],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eventData['images'] != null &&
                          eventData['images'].isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              eventData['images'][0],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                eventData['title'] ?? '',
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                                Icons.calendar_today,
                                _formatDateRange(eventData['startDate'],
                                    eventData['endDate']),
                                isDarkMode),
                            const SizedBox(height: 4),
                            _buildInfoRow(Icons.location_on,
                                eventData['address'] ?? '', isDarkMode),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                Icons.attach_money,
                                '${eventData['ticketPrice'] ?? 'N/A'}',
                                isDarkMode),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.category,
                              eventData['categories'] != null
                                  ? (eventData['categories'] as List<dynamic>)
                                      .join(', ')
                                  : 'N/A',
                              isDarkMode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.bookmark_add_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () =>
                          _showBookingDialog(context, eventId, eventData),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _bookEvent(eventId, eventData, ticketQuantity);
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

  void _showEventDetailsPopup(BuildContext context,
      Map<String, dynamic> eventData, String eventId, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
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
                          Text(
                            eventData['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            eventData['description'] ?? '',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (eventData['images'] != null &&
                              eventData['images'].isNotEmpty)
                            SizedBox(
                              height: 250,
                              child: CarouselSlider(
                                options: CarouselOptions(
                                  enableInfiniteScroll: false,
                                  autoPlay: false,
                                  enlargeCenterPage: true,
                                  viewportFraction: 0.8,
                                  aspectRatio: 16 / 9,
                                  initialPage: 0,
                                  scrollDirection: Axis.horizontal,
                                ),
                                items: (eventData['images'] as List<dynamic>)
                                    .map((image) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      image.toString(),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (eventData['images'] != null &&
                              eventData['images'].isNotEmpty)
                            const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.location_on,
                            eventData['address'] ?? '',
                            isDarkMode,
                          ),
                          const SizedBox(height: 8),
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
                            Icons.attach_money,
                            '${eventData['ticketPrice'] ?? ''}',
                            isDarkMode,
                          ),
                          const SizedBox(height: 8),
                          // ** Add the line below to display the number of booked tickets.**
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
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.category,
                            eventData['categories'] != null
                                ? (eventData['categories'] as List<dynamic>)
                                    .join(', ')
                                : 'N/A',
                            isDarkMode,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _bookEvent(String eventId, Map<String, dynamic> eventData,
      int ticketQuantity) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar('Please log in to book an event');
      return;
    }

    final maxParticipants = eventData['maxParticipants'] ?? 0;
    final bookingCount = await _getBookingCount(eventId);

    if (bookingCount + ticketQuantity > maxParticipants) {
      _showSnackBar('Not enough tickets available');
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
      _showSnackBar(
          '$ticketQuantity ticket(s) booked successfully for ${eventData['title']}');
    } catch (e) {
      _showSnackBar('Error booking event: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
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

  String _formatDateRange(String? startDateString, String? endDateString) {
    if (startDateString == null || endDateString == null) return '';
    final startDate = DateTime.parse(startDateString);
    final endDate = DateTime.parse(endDateString);
    final formatter = DateFormat('MMM d, y');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
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
}
