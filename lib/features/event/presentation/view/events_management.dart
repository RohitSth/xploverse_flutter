import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsManagement extends StatefulWidget {
  const EventsManagement({Key? key}) : super(key: key);

  @override
  State<EventsManagement> createState() => _EventsManagementState();
}

class _EventsManagementState extends State<EventsManagement> {
  final ImagePicker _picker = ImagePicker();
  RxList<XFile> selectedImages = <XFile>[].obs;
  final RxList<String> arrImagesUrl = <String>[].obs;
  RxList<String> eventImages = <String>[].obs;

  final FirebaseStorage storageRef = FirebaseStorage.instance;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController categoriesController = TextEditingController();
  final TextEditingController maxParticipantsController =
      TextEditingController();
  final TextEditingController ticketPriceController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;

  final CollectionReference allEvents =
      FirebaseFirestore.instance.collection('events');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _organizerUid;
  String? _currentEventId;

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

  Future<void> _selectImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      selectedImages.addAll(images);
    }
  }

  Future<void> uploadFunction(String eventId) async {
    arrImagesUrl.clear();
    for (XFile image in selectedImages) {
      String imageUrl = await uploadFile(image, eventId);
      arrImagesUrl.add(imageUrl);
    }
  }

  RxDouble uploadProgress = 0.0.obs;

  Future<String> uploadFile(XFile image, String eventId) async {
    UploadTask uploadTask = storageRef
        .ref()
        .child("event-images")
        .child(eventId)
        .child(image.name + DateTime.now().toString())
        .putFile(File(image.path));

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      uploadProgress.value = snapshot.bytesTransferred / snapshot.totalBytes;
    });

    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _addEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_organizerUid == null) {
        _showSnackBar('Please login as organizer to create events');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_organizerUid)
          .get();
      if (userDoc.exists && userDoc.get('usertype') != 'Organizer') {
        _showSnackBar('Only organizers can create events');
        return;
      }

      QuerySnapshot snapshot =
          await allEvents.where('title', isEqualTo: titleController.text).get();
      if (snapshot.docs.isNotEmpty) {
        _showSnackBar('An event with this title already exists');
        return;
      }

      String newEventId = allEvents.doc().id;
      await uploadFunction(newEventId);
      Map<String, dynamic> eventData = _getEventData();
      await allEvents.doc(newEventId).set(eventData);

      _showSnackBar('Event created successfully');
      _clearFields();
    } catch (e) {
      print('Error adding event: $e');
      _showSnackBar('Error creating event: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateEvent(String eventId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (selectedImages.isNotEmpty) {
        await uploadFunction(eventId);
      }

      Map<String, dynamic> eventData = _getEventData();
      await allEvents.doc(eventId).update(eventData);

      _showSnackBar('Event updated successfully');
      _clearFields();
    } catch (e) {
      print('Error updating event: $e');
      _showSnackBar('Error updating event: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      // Delete images from storage
      final storageRef =
          FirebaseStorage.instance.ref().child("event-images").child(eventId);
      final ListResult result = await storageRef.listAll();
      for (var item in result.items) {
        await item.delete();
      }

      // Delete event document
      await allEvents.doc(eventId).delete();

      _showSnackBar('Event deleted successfully');
    } catch (e) {
      print('Error deleting event: $e');
      _showSnackBar('Error deleting event: $e');
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
      'images': arrImagesUrl.isNotEmpty ? arrImagesUrl : eventImages,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'maxParticipants': int.tryParse(maxParticipantsController.text) ?? 0,
      'ticketPrice': double.tryParse(ticketPriceController.text) ?? 0,
      'organizerId': _organizerUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _populateEventData(String eventId) async {
    DocumentSnapshot eventDoc = await allEvents.doc(eventId).get();
    Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;

    setState(() {
      titleController.text = eventData['title'] ?? '';
      descriptionController.text = eventData['description'] ?? '';
      addressController.text = eventData['address'] ?? '';
      latitudeController.text = eventData['latitude']?.toString() ?? '';
      longitudeController.text = eventData['longitude']?.toString() ?? '';
      categoriesController.text = eventData['categories'] ?? '';
      eventImages.assignAll(List<String>.from(eventData['images'] ?? []));
      maxParticipantsController.text =
          eventData['maxParticipants']?.toString() ?? '';
      ticketPriceController.text = eventData['ticketPrice']?.toString() ?? '';

      if (eventData['startDate'] != null) {
        _startDate = DateTime.parse(eventData['startDate']);
        _startDateController.text =
            DateFormat('yyyy-MM-dd').format(_startDate!);
      }

      if (eventData['endDate'] != null) {
        _endDate = DateTime.parse(eventData['endDate']);
        _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
    });
  }

  bool _validateFields() {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        latitudeController.text.isNotEmpty &&
        longitudeController.text.isNotEmpty &&
        categoriesController.text.isNotEmpty &&
        (selectedImages.isNotEmpty || eventImages.isNotEmpty) &&
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
    selectedImages.clear();
    arrImagesUrl.clear();
    maxParticipantsController.clear();
    ticketPriceController.clear();
    _startDateController.clear();
    _endDateController.clear();
    eventImages.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentEventId = null;
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

  void _showEventDialog({String? eventId}) async {
    _currentEventId = eventId;
    bool isUpdate = eventId != null;

    if (isUpdate) {
      DocumentSnapshot eventDoc = await allEvents.doc(eventId).get();
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;

      setState(() {
        titleController.text = eventData['title'] ?? '';
        descriptionController.text = eventData['description'] ?? '';
        addressController.text = eventData['address'] ?? '';
        latitudeController.text = eventData['latitude']?.toString() ?? '';
        longitudeController.text = eventData['longitude']?.toString() ?? '';
        categoriesController.text = eventData['categories'] ?? '';
        eventImages.assignAll(List<String>.from(eventData['images'] ?? []));
        maxParticipantsController.text =
            eventData['maxParticipants']?.toString() ?? '';
        ticketPriceController.text = eventData['ticketPrice']?.toString() ?? '';

        if (eventData['startDate'] != null) {
          _startDate = DateTime.parse(eventData['startDate']);
          _startDateController.text =
              DateFormat('yyyy-MM-dd').format(_startDate!);
        }

        if (eventData['endDate'] != null) {
          _endDate = DateTime.parse(eventData['endDate']);
          _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
        }
      });
    } else {
      _clearFields();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 1),
          child: AlertDialog(
            title: Text(isUpdate ? "Update Event" : "Create Event"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(titleController, "Title"),
                  _buildTextField(descriptionController, "Description",
                      maxLines: 3),
                  _buildTextField(addressController, "Address"),
                  _buildTextField(latitudeController, "Latitude",
                      keyboardType: TextInputType.number),
                  _buildTextField(longitudeController, "Longitude",
                      keyboardType: TextInputType.number),
                  _buildTextField(categoriesController, "Categories"),
                  _buildImageSection(),
                  _buildTextField(
                      maxParticipantsController, "Maximum Participants",
                      keyboardType: TextInputType.number),
                  _buildTextField(ticketPriceController, "Ticket Price",
                      keyboardType: TextInputType.number),
                  _buildDateField(
                      _startDateController, 'Start Date', _selectStartDate),
                  _buildDateField(
                      _endDateController, 'End Date', _selectEndDate),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_validateFields()) {
                    Navigator.of(context).pop();
                    if (isUpdate) {
                      await _updateEvent(eventId!);
                    } else {
                      await _addEvent();
                    }
                  } else {
                    _showSnackBar('Please fill all fields');
                  }
                },
                child: Text(isUpdate ? "Update" : "Create"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label,
      Function(BuildContext) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => onTap(context),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Event Images",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...eventImages.map((imageUrl) =>
                    _buildImageTile(imageUrl, isNetworkImage: true)),
                ...selectedImages.map((image) => _buildImageTile(image.path)),
              ],
            )),
        ElevatedButton.icon(
          onPressed: _selectImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
        ),
      ],
    );
  }

  Widget _buildImageTile(String imagePath, {bool isNetworkImage = false}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isNetworkImage
                ? Image.network(imagePath, fit: BoxFit.cover)
                : Image.file(File(imagePath), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              if (isNetworkImage) {
                eventImages.remove(imagePath);
              } else {
                selectedImages.removeWhere((image) => image.path == imagePath);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
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
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    documentSnapshot['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd')
                        .format(DateTime.parse(documentSnapshot['startDate'])),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: Colors.blue,
                        onPressed: () =>
                            _showEventDialog(eventId: documentSnapshot.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () =>
                            _showDeleteConfirmation(documentSnapshot.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            bottom: 96.0), // Adjust the value for desired height
        child: FloatingActionButton(
          backgroundColor: const Color.fromARGB(100, 10, 123, 158),
          onPressed: () => _showEventDialog(),
          child: const Icon(
            Icons.add,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String eventId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Event"),
          content: const Text("Are you sure you want to delete this event?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Delete"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent(eventId);
              },
            ),
          ],
        );
      },
    );
  }
}
