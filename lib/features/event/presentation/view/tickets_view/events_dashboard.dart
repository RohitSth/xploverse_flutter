import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pdf/widgets.dart' as pw;

class ProfileDashboard extends StatelessWidget {
  const ProfileDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 0, 0, 0)
            : const Color(0xFFC9D6FF),
        title: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Text(
            'MY BOOKINGS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        const Color.fromARGB(255, 0, 0, 0),
                        const Color.fromARGB(255, 0, 38, 82),
                      ]
                    : [
                        const Color(0xFFC9D6FF),
                        const Color(0xFFE2E2E2),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          user == null
              ? const Center(child: Text('Please log in to view your bookings'))
              : _buildBookingsList(user.uid, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String userId, bool isDarkMode) {
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0),
          child: ListView.builder(
            itemCount: groupedBookings.length,
            itemBuilder: (context, index) {
              final eventId = groupedBookings.keys.elementAt(index);
              final bookings = groupedBookings[eventId]!;
              return _buildBookingCard(context, bookings, isDarkMode);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(
      BuildContext context, List<DocumentSnapshot> bookings, bool isDarkMode) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0, // Remove elevation since we'll use blur
          child: ClipRRect(
            // Use ClipRRect to clip the gradient
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              // Apply a blur effect
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Apply gradient
                  gradient: isDarkMode
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF212121),
                            Color(0xFF000000)
                          ], // Blue to Black
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE2E2E2),
                            Colors.white,
                          ], // Blue to White
                        ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () => _showTicketQRCodes(context, bookings, eventData),
                  borderRadius: BorderRadius.circular(15),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${_formatDate(eventData['startDate'])}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tickets: $ticketCount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Icon(Icons.qr_code,
                              color: isDarkMode ? Colors.white : Colors.black),
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBooking(context, bookings),
                            tooltip: 'Delete Booking',
                          ),
                        ],
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding:
                  const EdgeInsets.only(top: 58, left: 0, right: 0, bottom: 96),
              child: Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.90,
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
                            colors: [
                              Colors.white,
                              Color(0xFF4A90E2),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eventData['title'] ?? 'Event Tickets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Combine Tickets',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: combineTickets,
                                onChanged: (value) {
                                  setState(() {
                                    combineTickets = value;
                                  });
                                },
                                activeTrackColor:
                                    const Color.fromARGB(255, 10, 123, 158),
                                activeColor:
                                    const Color.fromARGB(255, 255, 255, 255),
                              ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => _downloadTicketPDF(
                                  context, bookings, eventData, combineTickets),
                              child: const Text('Download Ticket PDF'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Close',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
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
            foregroundColor: isDarkMode ? Colors.white : Colors.black,
          ),
          _buildTicketInvoice(bookings, eventData,
              combined: true, width: MediaQuery.of(context).size.width * 0.90),
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
            _buildTicketInvoice([bookings[index]], eventData,
                width: MediaQuery.of(context).size.width * 0.90),
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
      {bool combined = false, required double width}) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: width, // Use the provided width
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
          Text('Venue: ${eventData['address'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Tickets: ${combined ? bookings.length : 1}'),
          Text('Booking ID: ${combined ? 'Multiple' : bookings.first.id}'),
          const SizedBox(height: 8),
          Text(
              'Total Price: \$${_calculateTotalPrice(eventData, bookings.length)}'),
        ],
      ),
    );
  }

  String _calculateTotalPrice(Map<String, dynamic> eventData, int ticketCount) {
    double total = 0;
    // Assuming 'ticketPrice' is stored in the eventData
    final ticketPrice = eventData['ticketPrice'] ?? 0;
    total = ticketPrice * ticketCount;
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
              pw.Text(
                  'Total Price: \$${_calculateTotalPrice(eventData, bookings.length)}'),
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
          SnackBar(
            content: Text('PDF saved to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
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
            title: const Center(
                child: Text(
              'DELETE TICKET',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            content: const Text('Are you sure you want to delete this ticket?'),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
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
            const SnackBar(
              content: Text('Ticket deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting ticket: $e'),
              backgroundColor: Colors.red,
            ),
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
                    Text('$ticketsToDelete ticket(s) deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting ticket(s): $e'),
                backgroundColor: Colors.red,
              ),
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
