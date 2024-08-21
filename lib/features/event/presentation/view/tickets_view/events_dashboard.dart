import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pdf/widgets.dart' as pw;

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
      builder: (BuildContext dialogContext) {
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
                          ? _buildCombinedTicketInvoice(
                              dialogContext, bookings, eventData)
                          : _buildIndividualTicketInvoices(
                              dialogContext, bookings, eventData),
                    ),
                    ElevatedButton(
                      onPressed: () => _downloadTicketPDF(
                          context, bookings, eventData, combineTickets),
                      child: const Text('Download Ticket PDF'),
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

  Widget _buildCombinedTicketInvoice(BuildContext context,
      List<DocumentSnapshot> bookings, Map<String, dynamic> eventData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          QrImageView(
            data: bookings.map((b) => b.id).join(','),
            version: QrVersions.auto,
            size: 200.0,
            gapless: false,
            // ignore: deprecated_member_use
            foregroundColor: isDarkMode ? Colors.white : Colors.black,
          ),
          _buildTicketInvoice(bookings, eventData, combined: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildIndividualTicketInvoices(BuildContext context,
      List<DocumentSnapshot> bookings, Map<String, dynamic> eventData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            _buildTicketInvoice([bookings[index]], eventData),
            const SizedBox(height: 16),
            QrImageView(
              data: bookings[index].id,
              version: QrVersions.auto,
              size: 150.0,
              gapless: false,
              foregroundColor: isDarkMode ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildTicketInvoice(
      List<DocumentSnapshot> bookings, Map<String, dynamic> eventData,
      {bool combined = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventData['title'] ?? 'Event',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Date: ${_formatDate(eventData['startDate'])}'),
          Text('Venue: ${eventData['venue'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Tickets: ${combined ? bookings.length : 1}'),
          Text('Booking ID: ${combined ? 'Multiple' : bookings.first.id}'),
          const SizedBox(height: 8),
          // Assuming you have a 'price' field in your bookings collection
          Text('Total Price: \$${_calculateTotalPrice(bookings)}'),
        ],
      ),
    );
  }

  String _calculateTotalPrice(List<DocumentSnapshot> bookings) {
    double total = 0;
    for (var booking in bookings) {
      final bookingData = booking.data() as Map<String, dynamic>;
      total += bookingData['price'] ?? 0; // Access 'price' from each booking
    }
    return total.toStringAsFixed(2);
  }

  Future<void> _downloadTicketPDF(
      BuildContext context,
      List<DocumentSnapshot> bookings,
      Map<String, dynamic> eventData,
      bool combineTickets) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                eventData['title'] ?? 'Event Ticket',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Date: ${_formatDate(eventData['startDate'])}'),
              pw.Text('Venue: ${eventData['venue'] ?? 'N/A'}'),
              pw.SizedBox(height: 20),
              pw.Text('Tickets: ${combineTickets ? bookings.length : 1}'),
              pw.Text(
                  'Booking ID: ${combineTickets ? 'Multiple' : bookings.first.id}'),
              pw.SizedBox(height: 20),
              pw.Text('Total Price: \$${_calculateTotalPrice(bookings)}'),
              pw.SizedBox(height: 40),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: combineTickets
                    ? bookings.map((b) => b.id).join(',')
                    : bookings.first.id,
                width: 200,
                height: 200,
              ),
            ],
          );
        },
      ),
    );

    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (status.isGranted) {
        // Get the documents directory
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final file = File('${directory.path}/event_ticket.pdf');

        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to ${file.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $e')),
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
                      Navigator.of(context).pop(ticketsToDelete);
                    },
                  ),
                ],
              );
            },
          );
        },
      ).then((ticketsToDelete) async {
        if (ticketsToDelete != null && ticketsToDelete > 0) {
          try {
            // Delete the specified number of bookings
            for (int i = 0; i < ticketsToDelete; i++) {
              await bookings[i].reference.delete();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('$ticketsToDelete ticket(s) deleted successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting ticket(s): $e')),
            );
          }
        }
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    final date = DateTime.parse(dateString);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
