import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String?> getUserProfilePictureUrl() async {
  final User? user = FirebaseAuth.instance.currentUser;
  print('Current user: ${user?.uid}');
  if (user != null) {
    try {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      print('User data: ${userData.data()}');
      return userData.data()?['profilePictureUrl'] ?? user.photoURL;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
  return null;
}
