import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDashboard extends StatelessWidget {
  const ProfileDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Profile Dashboard'),
        ),
        body: user == null
            ? const Center(child: Text('Please log in to view your dashboard'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: user.uid)
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

                  final bookings = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final bookingData =
                          bookings[index].data() as Map<String, dynamic>;
                      print(
                          'Booking data: $bookingData'); // Keep this for debugging

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(bookingData['eventTitle'] ?? 'No title'),
                          subtitle: Text(
                              'Date: ${_formatDate(bookingData['eventDate'])}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red), // Red delete icon
                            onPressed: () => _showCancelConfirmation(context,
                                bookings[index].id, bookingData['eventTitle']),
                          ),
                        ),
                      );
                    },
                  );
                },
              ));
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }

  void _showCancelConfirmation(
      BuildContext context, String bookingId, String eventTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: Text(
              'Are you sure you want to cancel the booking for "$eventTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _cancelBooking(context, bookingId),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _cancelBooking(BuildContext context, String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: $e')),
      );
      Navigator.of(context).pop();
    }
  }
}
