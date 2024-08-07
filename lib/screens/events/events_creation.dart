import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsCreation extends StatefulWidget {
  const EventsCreation({Key? key}) : super(key: key);

  @override
  State<EventsCreation> createState() => _EventsCreationState();
}

class _EventsCreationState extends State<EventsCreation> {
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

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildDialogBox(
          name: "Event Creation",
          condition: "Create",
          onPressed: () async {
            if (_validateFields()) {
              await _addEvent();
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

      // Create a new document in Firestore
      await allEvents.add({
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );

      Navigator.of(context).pop(); // Close the dialog
      _clearFields();
    } catch (e) {
      print('Error adding event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
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
      body: StreamBuilder<QuerySnapshot>(
        stream: allEvents.snapshots(),
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
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85.0),
        child: FloatingActionButton(
          onPressed: _showCreateEventDialog,
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
