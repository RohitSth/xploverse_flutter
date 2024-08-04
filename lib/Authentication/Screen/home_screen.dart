import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/Screen/login.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("HomePage"),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("HomePage Welcome"),
            MyButtons(
              onTap: () async {
                await AuthServices().signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const LoginScreen()));
              },
              text: 'Logout',
            ),
            // For users who signed in with google account
            Image.network("${FirebaseAuth.instance.currentUser!.photoURL}"),
            Text("${FirebaseAuth.instance.currentUser!.email}"),
            Text("${FirebaseAuth.instance.currentUser!.displayName}"),
          ],
        )));
  }
}
