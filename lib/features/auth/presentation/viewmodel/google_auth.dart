import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
    forceCodeForRefreshToken: true,
    // clientId: 'YOUR_CLIENT_ID_HERE', // Uncomment and add for iOS
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signInWithGoogle(String userType) async {
    try {
      // Sign out from any previous sessions
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // User cancelled the sign-in process
        return "User cancelled sign in";
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if this is a new user
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // If it's a new user, save their info including the user type
          Map<String, dynamic> userData = {
            'uid': user.uid,
            'email': user.email,
            'username': user.displayName,
            'usertype': userType,
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
        }

        return "success";
      }
      return "Google Sign In failed";
    } catch (e) {
      print('Error during Google Sign In: $e');
      return "Error: $e";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
