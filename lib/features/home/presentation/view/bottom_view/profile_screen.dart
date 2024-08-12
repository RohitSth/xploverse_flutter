import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> pickImage() async {
    if (isGoogleSignIn) return; // Don't allow Google users to change picture

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
    final backgroundColor = isDarkMode ? Colors.black : Colors.grey[300];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.grey[200];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: allUsers.doc(user?.uid).snapshots(),
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
              : (imageUrl ?? userData['profilePictureUrl'] ?? user?.photoURL);
          bool isOrganizer = userData['usertype'] == 'Organizer';

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
                                ? const Icon(Icons.person,
                                    size: 100, color: Colors.grey)
                                : null,
                          ),
                          if (isLoading)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width:
                                      120, // width and height should match the CircleAvatar
                                  height:
                                      120, // radius to create the same size as CircleAvatar
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
                                child: CircleAvatar(
                                  backgroundColor:
                                      const Color.fromARGB(255, 10, 123, 158),
                                  radius: 20,
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userData['username'] ?? user?.displayName ?? 'Username',
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
                          fontSize: 14,
                          color: Color.fromARGB(255, 10, 123, 158),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 10, 123, 158),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userData['email'] ??
                                    user?.email ??
                                    'Email not available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Bio:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 10, 123, 158),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userData['bio'] ?? 'No bio available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              if (isOrganizer) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'Phone:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 10, 123, 158),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  userData['phone'] ??
                                      'No phone number available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
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
                        child: Text(isOrganizer ? 'Edit Profile' : 'Edit Bio'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUpdateProfileDialog(Map<String, dynamic> userData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController bioController =
        TextEditingController(text: userData['bio'] ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: userData['phone'] ?? '');

    bool isOrganizer = userData['usertype'] == 'Organizer';
    bool isGoogleSignIn = user?.providerData
            .any((userInfo) => userInfo.providerId == 'google.com') ??
        false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            isOrganizer ? 'Update Profile' : 'Update Bio',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  maxLines: 3,
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                if (isOrganizer)
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Map<String, dynamic> updateData = {
                    'bio': bioController.text.trim(),
                  };

                  if (isOrganizer) {
                    updateData['phone'] = phoneController.text.trim();
                  }

                  await allUsers.doc(user?.uid).update(updateData);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                } catch (e) {
                  print('Error updating profile: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update profile')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
