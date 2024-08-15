import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileDashboard extends StatelessWidget {
  const ProfileDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your bookings'))
          : _buildBookingsList(user.uid),
    );
  }

  Widget _buildBookingsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No booked events'));
        }

        // Group bookings by eventId
        Map<String, List<DocumentSnapshot>> groupedBookings = {};
        for (var doc in snapshot.data!.docs) {
          final bookingData = doc.data() as Map<String, dynamic>;
          final eventId = bookingData['eventId'];
          if (!groupedBookings.containsKey(eventId)) {
            groupedBookings[eventId] = [];
          }
          groupedBookings[eventId]!.add(doc);
        }

        return ListView.builder(
          itemCount: groupedBookings.length,
          itemBuilder: (context, index) {
            final eventId = groupedBookings.keys.elementAt(index);
            final bookings = groupedBookings[eventId]!;
            return _buildBookingCard(context, bookings);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(
      BuildContext context, List<DocumentSnapshot> bookings) {
    final firstBooking = bookings.first.data() as Map<String, dynamic>;
    final eventId = firstBooking['eventId'];
    final ticketCount = bookings.length;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('events').doc(eventId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox();
        }

        final eventData = snapshot.data!.data() as Map<String, dynamic>?;
        if (eventData == null) {
          return const SizedBox();
        }

        return Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          shadowColor: Colors.grey.withOpacity(0.5), // Subtle shadow effect
          child: InkWell(
            onTap: () => _showTicketQRCodes(context, bookings, eventData),
            borderRadius:
                BorderRadius.circular(15), // Rounded corners for ripple effect
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventImage(eventData),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventData['title'] ?? 'No title',
                          style: const TextStyle(
                            fontSize: 20, // Slightly larger title font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height:
                                8), // Increased spacing for better separation
                        Text(
                          'Date: ${_formatDate(eventData['startDate'])}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors
                                .grey[700], // Subtle color for less emphasis
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tickets: $ticketCount',
                          style: const TextStyle(
                            fontSize: 16, // Slightly larger font size
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 79, 155, 218),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(Icons.qr_code,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(height: 8), // Spacing between icons
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBooking(context, bookings),
                        tooltip:
                            'Delete Booking', // Tooltip for better accessibility
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventImage(Map<String, dynamic> eventData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: eventData['images'] != null && eventData['images'].isNotEmpty
          ? Image.network(
              eventData['images'][0],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            )
          : Container(
              width: 60,
              height: 60,
              color: Colors.grey,
              child: const Icon(Icons.event, color: Colors.white),
            ),
    );
  }

  void _showTicketQRCodes(BuildContext context, List<DocumentSnapshot> bookings,
      Map<String, dynamic> eventData) {
    bool combineTickets = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eventData['title'] ?? 'Event Tickets',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Combine tickets:'),
                        Switch(
                          value: combineTickets,
                          onChanged: (value) {
                            setState(() {
                              combineTickets = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: combineTickets
                          ? _buildCombinedQRCode(bookings)
                          : _buildIndividualQRCodes(bookings),
                    ),
                    ElevatedButton(
                      onPressed: () => _downloadQRCodes(
                          context, bookings, eventData, combineTickets),
                      child: const Text('Download QR Code(s)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
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

  Widget _buildCombinedQRCode(List<DocumentSnapshot> bookings) {
    final combinedData = bookings.map((b) => b.id).join(',');
    return Column(
      children: [
        QrImageView(
          data: combinedData,
          version: QrVersions.auto,
          size: 200.0,
          gapless: false,
        ),
        const Text('Combined Ticket QR Code'),
      ],
    );
  }

  Widget _buildIndividualQRCodes(List<DocumentSnapshot> bookings) {
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final bookingId = bookings[index].id;
        return Column(
          children: [
            QrImageView(
              data: bookingId,
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
            ),
            Text('Ticket ${index + 1}'),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _downloadQRCodes(
      BuildContext context,
      List<DocumentSnapshot> bookings,
      Map<String, dynamic> eventData,
      bool combineTickets) async {
    // Check Android version and request appropriate permission
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    bool permissionGranted = false;

    if (androidInfo.version.sdkInt >= 30) {
      // Android 11 (API 30) and above
      permissionGranted =
          await Permission.manageExternalStorage.request().isGranted;
    } else {
      // Below Android 11
      permissionGranted = await Permission.storage.request().isGranted;
    }

    if (!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Storage permission is required to download QR codes. Please grant permission in app settings.'),
        ),
      );
      // Open app settings so the user can grant the permission
      await openAppSettings();
      return;
    }

    try {
      // Get the appropriate directory
      Directory? directory;
      if (androidInfo.version.sdkInt >= 30) {
        // For Android 11 and above, use getExternalStorageDirectory
        directory = await getExternalStorageDirectory();
      } else {
        // For older versions, you can use getExternalStorageDirectory or another method
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create a new directory for the event
      final eventDir = Directory('${directory.path}/EventQRCodes');
      if (!await eventDir.exists()) {
        await eventDir.create(recursive: true);
      }

      // Rest of your QR code generation and saving logic...
      // (Keep the existing code for generating and saving QR codes)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'QR code(s) and event information saved to ${eventDir.path}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR codes: $e')),
      );
    }
  }

  Future<void> _deleteBooking(
      BuildContext context, List<DocumentSnapshot> bookings) async {
    int totalTickets = bookings.length;

    if (totalTickets == 1) {
      // Directly prompt to delete the single ticket
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Ticket'),
            content: const Text('Are you sure you want to delete this ticket?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmDelete) {
        try {
          await bookings.first.reference.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket deleted successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting ticket: $e')),
          );
        }
      }
    } else {
      int ticketsToDelete = totalTickets;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Delete Tickets'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total tickets: $totalTickets'),
                    const SizedBox(height: 10),
                    Text('Tickets to delete: $ticketsToDelete'),
                    Slider(
                      value: ticketsToDelete.toDouble(),
                      min: 1,
                      max: totalTickets.toDouble(),
                      divisions: totalTickets - 1,
                      label: ticketsToDelete.toString(),
                      onChanged: (double value) {
                        setState(() {
                          ticketsToDelete = value.round();
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text('Delete'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        for (int i = 0; i < ticketsToDelete; i++) {
                          await bookings[i].reference.delete();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '$ticketsToDelete ticket(s) deleted successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error deleting ticket(s): $e')),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    final date = DateTime.parse(dateString);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
