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
        title: const Text(
          'XPLORATION',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your dashboard'))
          : _buildBookingsList(user.uid),
    );
  }

  // Build the list of bookings for the current user
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

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              _buildBookingCard(context, bookings[index]),
        );
      },
    );
  }

  // Build a card for a single booking
  Widget _buildBookingCard(BuildContext context, DocumentSnapshot booking) {
    final bookingData = booking.data() as Map<String, dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('events')
          .doc(bookingData['eventId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(); // Skip this item if there's an error or no data
        }

        final eventData = snapshot.data!.data() as Map<String, dynamic>?;
        if (eventData == null) {
          return const SizedBox(); // Skip this item if eventData is null
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () => _showEventDetails(context, bookingData),
            child:
                _buildCardContent(context, eventData, bookingData, booking.id),
          ),
        );
      },
    );
  }

  // Build the content of a booking card
  Widget _buildCardContent(BuildContext context, Map<String, dynamic> eventData,
      Map<String, dynamic> bookingData, String bookingId) {
    return Container(
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
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booked: ${_formatTimestamp(bookingData['bookingDate'])}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildAddressRow(eventData['address']),
              ],
            ),
          ),
          _buildActionButtons(
              context, bookingId, eventData['title'], bookingData),
        ],
      ),
    );
  }

  // Build the event image widget
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

  // Build the address row widget
  Widget _buildAddressRow(String? address) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            address ?? 'No address',
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Build action buttons for the booking card
  Widget _buildActionButtons(BuildContext context, String bookingId,
      String eventTitle, Map<String, dynamic> bookingData) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () =>
              _showCancelConfirmation(context, bookingId, eventTitle),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
          onPressed: () => _showEventDetails(context, bookingData),
        ),
      ],
    );
  }

  // Format timestamp to string
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    DateTime date;
    if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.parse(dateString);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Show event details dialog
  void _showEventDetails(
      BuildContext context, Map<String, dynamic> bookingData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    FirebaseFirestore.instance
        .collection('events')
        .doc(bookingData['eventId'])
        .get()
        .then((eventDoc) {
      if (eventDoc.exists) {
        final eventData = eventDoc.data() as Map<String, dynamic>;
        showDialog(
          context: context,
          builder: (context) => _buildEventDetailsDialog(
              context, eventData, bookingData, isDarkMode),
        );
      } else {
        _showEventNotFoundDialog(context);
      }
    });
  }

  // Build event details dialog
  Widget _buildEventDetailsDialog(
      BuildContext context,
      Map<String, dynamic> eventData,
      Map<String, dynamic> bookingData,
      bool isDarkMode) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              eventData['title']?.toUpperCase() ?? 'Event Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildEventDescription(eventData, isDarkMode),
            const SizedBox(height: 15),
            _buildEventInfoRows(eventData, isDarkMode),
            const SizedBox(height: 15),
            _buildOrganizerInfo(eventData, isDarkMode),
            const SizedBox(height: 15),
            _buildInfoRow(
              icon: Icons.bookmark,
              text: _formatTimestamp(bookingData['bookingDate']),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.lightBlueAccent : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build event description widget
  Widget _buildEventDescription(
      Map<String, dynamic> eventData, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        eventData['description'] ?? 'No description available',
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  // Build event info rows
  Widget _buildEventInfoRows(Map<String, dynamic> eventData, bool isDarkMode) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.location_on,
          text: eventData['address'] ?? 'N/A',
          isDarkMode: isDarkMode,
        ),
        _buildInfoRow(
          icon: Icons.calendar_today,
          text:
              '${_formatDate(eventData['startDate'])} - ${_formatDate(eventData['endDate'])}',
          isDarkMode: isDarkMode,
        ),
        _buildInfoRow(
          icon: Icons.attach_money,
          text: '${eventData['ticketPrice'] ?? 'N/A'}',
          isDarkMode: isDarkMode,
        ),
        _buildInfoRow(
          icon: Icons.people,
          text: '${eventData['maxParticipants'] ?? 'N/A'} MAX',
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  // Build organizer info widget
  Widget _buildOrganizerInfo(Map<String, dynamic> eventData, bool isDarkMode) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(eventData['organizerId'])
          .get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Organizer information not available');
        }

        Map<String, dynamic> organizerData =
            snapshot.data!.data() as Map<String, dynamic>;
        return Column(
          children: [
            _buildInfoRow(
              icon: Icons.business,
              text: '${organizerData['organization'] ?? 'N/A'}',
              isDarkMode: isDarkMode,
            ),
            _buildInfoRow(
              icon: Icons.phone,
              text: organizerData['phone'] ?? 'N/A',
              isDarkMode: isDarkMode,
            ),
          ],
        );
      },
    );
  }

  // Build info row widget
  Widget _buildInfoRow(
      {required IconData icon,
      required String text,
      required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.lightBlueAccent : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show event not found dialog
  void _showEventNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event Not Found'),
        content: const Text('The event details are no longer available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show cancellation confirmation dialog
  void _showCancelConfirmation(
      BuildContext context, String bookingId, String eventTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

  // Cancel booking
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
