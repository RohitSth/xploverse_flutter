import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsManagement extends StatefulWidget {
  const EventsManagement({Key? key}) : super(key: key);

  @override
  State<EventsManagement> createState() => _EventsManagementState();
}

class _EventsManagementState extends State<EventsManagement> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController categoriesController = TextEditingController();
  final TextEditingController imagesController = TextEditingController();
  final TextEditingController maxParticipantsController =
      TextEditingController();
  final TextEditingController ticketPriceController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  final CollectionReference allEvents =
      FirebaseFirestore.instance.collection('events');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _organizerUid;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _organizerUid = user.uid;
      });
    }
  }

  void _showEventDialog({String? eventId}) {
    bool isUpdate = eventId != null;
    if (isUpdate) {
      _populateEventData(eventId);
    } else {
      _clearFields();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildDialogBox(
          name: isUpdate ? "Update Event" : "Create Event",
          condition: isUpdate ? "Update" : "Create",
          onPressed: () async {
            if (_validateFields()) {
              if (isUpdate) {
                await _updateEvent(eventId);
              } else {
                await _addEvent();
              }
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _addEvent() async {
    if (_organizerUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please login as organizer to create events')),
      );
      return;
    }

    try {
      QuerySnapshot snapshot =
          await allEvents.where('title', isEqualTo: titleController.text).get();
      if (snapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An event with this title already exists')),
        );
        return;
      }

      await allEvents.add(_getEventData());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );

      _clearFields();
    } catch (e) {
      print('Error adding event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    }
  }

  Future<void> _updateEvent(String eventId) async {
    try {
      await allEvents.doc(eventId).update(_getEventData());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );

      _clearFields();
    } catch (e) {
      print('Error updating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating event: $e')),
      );
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await allEvents.doc(eventId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
  }

  Map<String, dynamic> _getEventData() {
    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'address': addressController.text,
      'latitude': double.tryParse(latitudeController.text) ?? 0,
      'longitude': double.tryParse(longitudeController.text) ?? 0,
      'categories': categoriesController.text,
      'images': imagesController.text,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'maxParticipants': int.tryParse(maxParticipantsController.text) ?? 0,
      'ticketPrice': double.tryParse(ticketPriceController.text) ?? 0,
      'organizerId': _organizerUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  void _populateEventData(String eventId) async {
    DocumentSnapshot eventDoc = await allEvents.doc(eventId).get();
    Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;

    titleController.text = eventData['title'] ?? '';
    descriptionController.text = eventData['description'] ?? '';
    addressController.text = eventData['address'] ?? '';
    latitudeController.text = eventData['latitude']?.toString() ?? '';
    longitudeController.text = eventData['longitude']?.toString() ?? '';
    categoriesController.text = eventData['categories'] ?? '';
    imagesController.text = eventData['images'] ?? '';
    maxParticipantsController.text =
        eventData['maxParticipants']?.toString() ?? '';
    ticketPriceController.text = eventData['ticketPrice']?.toString() ?? '';

    if (eventData['startDate'] != null) {
      _startDate = DateTime.parse(eventData['startDate']);
      _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    }

    if (eventData['endDate'] != null) {
      _endDate = DateTime.parse(eventData['endDate']);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
    }
  }

  bool _validateFields() {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        latitudeController.text.isNotEmpty &&
        longitudeController.text.isNotEmpty &&
        categoriesController.text.isNotEmpty &&
        imagesController.text.isNotEmpty &&
        maxParticipantsController.text.isNotEmpty &&
        ticketPriceController.text.isNotEmpty &&
        _startDate != null &&
        _endDate != null;
  }

  void _clearFields() {
    titleController.clear();
    descriptionController.clear();
    addressController.clear();
    latitudeController.clear();
    longitudeController.clear();
    categoriesController.clear();
    imagesController.clear();
    maxParticipantsController.clear();
    ticketPriceController.clear();
    _startDateController.clear();
    _endDateController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _startDateController.text =
            DateFormat('yyyy-MM-dd').format(_startDate!);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: allEvents
            .where('organizerId', isEqualTo: _organizerUid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (streamSnapshot.hasError) {
            return Center(child: Text('Error: ${streamSnapshot.error}'));
          }
          if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No events found'));
          }
          return ListView.builder(
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot documentSnapshot =
                  streamSnapshot.data!.docs[index];
              return ListTile(
                title: Text(
                  documentSnapshot['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(documentSnapshot['description']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEventDialog(eventId: documentSnapshot.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteEvent(documentSnapshot.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85.0),
        child: FloatingActionButton(
          onPressed: () => _showEventDialog(),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDialogBox({
    required String name,
    required String condition,
    required VoidCallback onPressed,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(),
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title")),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description")),
              TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address")),
              TextField(
                  controller: latitudeController,
                  decoration: const InputDecoration(labelText: "Latitude")),
              TextField(
                  controller: longitudeController,
                  decoration: const InputDecoration(labelText: "Longitude")),
              TextField(
                  controller: categoriesController,
                  decoration: const InputDecoration(labelText: "Categories")),
              TextField(
                  controller: imagesController,
                  decoration: const InputDecoration(labelText: "Images")),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _startDateController,
                          decoration:
                              const InputDecoration(labelText: 'Start Date'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectEndDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _endDateController,
                          decoration:
                              const InputDecoration(labelText: 'End Date'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TextField(
                  controller: maxParticipantsController,
                  decoration:
                      const InputDecoration(labelText: "Maximum Participants")),
              TextField(
                  controller: ticketPriceController,
                  decoration: const InputDecoration(labelText: "Ticket Price")),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: onPressed, child: Text(condition)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
