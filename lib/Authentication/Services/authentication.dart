import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  // For storing data in Cloud Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // For Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For Signup
  Future<String> signUpUser(
      {required String username,
      required String email,
      required String password,
      required String usertype}) async {
    String res = "Some err occurred!!!";
    try {
      if (email.isNotEmpty || password.isNotEmpty || username.isNotEmpty) {
        // Register user in firebase
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        // Adding user to cloud firestore
        await _firestore.collection("users").doc(credential.user!.uid).set({
          'username': username,
          'uid': credential.user!.uid,
          'email': email,
          'usertype': usertype
        });
        res = "success";
      }
    } catch (e) {
      return e.toString();
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
}
