import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
      // Register user in firebase
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Adding user to cloud firestore
      await _firestore.collection("users").doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'username': username,
        'email': email,
        'password': password,
        'usertype': usertype
      });
    } catch (e) {
      print(e.toString());
    }
    return res;
  }
}
