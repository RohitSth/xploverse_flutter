import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signInWithGoogle(String userType) async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          // Check if this is a new user
          final DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            // If it's a new user, save their info including the user type
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'username': user.displayName,
              'usertype': userType,
            });
          } else {
            // If user already exists, update the usertype
            await _firestore.collection('users').doc(user.uid).update({
              'usertype': userType,
            });
          }

          return "success";
        }
      }
      return "Google Sign In failed";
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
