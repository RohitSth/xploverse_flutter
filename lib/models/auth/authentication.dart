import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  // For storing data in Cloud Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // For Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // For Signup
  Future<String> signUpUser({
    required String username,
    required String email,
    required String password,
    required String usertype,
    String? organization,
    String? phone,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        Map<String, dynamic> userData = {
          'username': username,
          'uid': credential.user!.uid,
          'email': email,
          'usertype': usertype,
        };

        if (usertype == 'Organizer') {
          if (organization != null && phone != null) {
            userData['organization'] = organization;
            userData['phone'] = phone;
          } else {
            return "Organization and phone are required for Organizer signup";
          }
        }

        await _firestore
            .collection("users")
            .doc(credential.user!.uid)
            .set(userData);
        res = "success";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // For Login
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some err occurred!!!";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        // Login user with email and password
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        res = 'success';
      } else {
        res = "Please enter all the field";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  // For Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
