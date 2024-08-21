import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CollectionReference allUsers =
      FirebaseFirestore.instance.collection('users');
  final User? user = FirebaseAuth.instance.currentUser;

  final ImagePicker _imagePicker = ImagePicker();
  String? imageUrl;

  bool get isGoogleSignIn =>
      user?.providerData
          .any((userInfo) => userInfo.providerId == 'google.com') ??
      false;

  bool isLoading = false;
  int totalBookings = 0;
  int totalEvents = 0;
  int createdEvents = 0;

  final _bookingStream = BehaviorSubject<int>();
  final _createdEventStream = BehaviorSubject<int>();
  final _bookedEventStream = BehaviorSubject<int>();

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _bookingStream.close();
    _createdEventStream.close();
    _bookedEventStream.close();
    super.dispose();
  }

  void _setupListeners() {
    // Listener for booking changes
    _bookingStream.listen((value) {
      setState(() {
        totalBookings = value;
      });
    });

    // Listener for created event changes
    _createdEventStream.listen((value) {
      setState(() {
        createdEvents = value;
      });
    });

    // Listener for booked event changes
    _bookedEventStream.listen((value) {
      setState(() {
        totalEvents = value;
      });
    });

    // Fetch initial booking and event data
    fetchBookingInfo();
    fetchCreatedEvents();
  }

  Future<void> fetchBookingInfo() async {
    try {
      // Listen to changes in bookings collection for this user
      FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid)
          .snapshots()
          .listen((snapshot) {
        // Only emit the event if the number of bookings changes
        if (snapshot.docs.length != totalBookings) {
          _bookingStream.add(snapshot.docs.length);

          // Update the unique booked events count
          _bookedEventStream
              .add(snapshot.docs.map((doc) => doc['eventId']).toSet().length);
        }
      });
    } catch (e) {
      print("Failed to retrieve booking information: $e");
    }
  }

  Future<void> fetchCreatedEvents() async {
    try {
      // Listen to changes in events collection for this user
      FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: user?.uid)
          .snapshots()
          .listen((snapshot) {
        // Only emit the event if the number of created events changes
        if (snapshot.docs.length != createdEvents) {
          _createdEventStream.add(snapshot.docs.length);
        }
      });
    } catch (e) {
      print("Failed to retrieve created events: $e");
    }
  }

  Future<void> pickImage() async {
    if (isGoogleSignIn) return;

    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await uploadImageToFirebase(File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to pick image: $e"),
        ),
      );
    }
  }

  Future<void> uploadImageToFirebase(File image) async {
    setState(() {
      isLoading = true;
    });
    try {
      Reference reference = FirebaseStorage.instance
          .ref()
          .child("images/${DateTime.now().microsecondsSinceEpoch}.png");

      await reference.putFile(image).whenComplete(() async {
        String downloadUrl = await reference.getDownloadURL();
        await allUsers
            .doc(user?.uid)
            .update({'profilePictureUrl': downloadUrl});
        setState(() {
          imageUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            content: Text("Upload Successful!"),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to upload image: $e"),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.grey[50];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF1E1E1E), const Color(0xFF323232)]
                    : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: allUsers
                .doc(user?.uid)
                .snapshots()
                .debounceTime(const Duration(milliseconds: 500)),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('No user data found'));
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String? profilePictureUrl = isGoogleSignIn
                  ? user?.photoURL
                  : (imageUrl ??
                      userData['profilePictureUrl'] ??
                      user?.photoURL);
              bool isOrganizer = userData['usertype'] == 'Organizer';

              // Fetch created events if the user is an organizer
              if (isOrganizer) {
                fetchCreatedEvents();
              }

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: profilePictureUrl != null
                                    ? NetworkImage(profilePictureUrl)
                                    : null,
                                child: profilePictureUrl == null
                                    ? Icon(Icons.person,
                                        size: 100, color: Colors.grey[400])
                                    : null,
                              ),
                              if (isLoading)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!isGoogleSignIn)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: pickImage,
                                    child: const CircleAvatar(
                                      backgroundColor: Color(0xFF0A7B9E),
                                      radius: 20,
                                      child: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            userData['username'] ??
                                user?.displayName ??
                                'Username',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            (userData['usertype'] ?? 'User Type').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black26,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoText('Email', userData['email']),
                                  const SizedBox(height: 20),
                                  _buildInfoText('Bio', userData['bio']),
                                  if (!isOrganizer) ...[
                                    const SizedBox(height: 20),
                                    _buildInfoText(
                                        'Total Bookings', '$totalBookings'),
                                    _buildInfoText(
                                        'Total Booked Events', '$totalEvents'),
                                  ] else ...[
                                    const SizedBox(height: 20),
                                    _buildInfoText(
                                        'Created Events', '$createdEvents'),
                                    _buildInfoText('Phone', userData['phone']),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              _showUpdateProfileDialog(userData);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 255, 255),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                            ),
                            child: const Text(
                              'Update Profile',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _showUpdateProfileDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newBio = userData['bio'] ?? '';
        return AlertDialog(
          title: const Text('Update Bio'),
          content: TextField(
            onChanged: (value) {
              newBio = value;
            },
            controller: TextEditingController(text: newBio),
            decoration: const InputDecoration(
              hintText: 'Enter your new bio',
            ),
            maxLines: 5,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                allUsers.doc(user?.uid).update({'bio': newBio}).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update profile: $error'),
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }
}
