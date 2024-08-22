import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xploverse/features/event/presentation/widgets/snackbar.dart';

class PasswordForget extends StatefulWidget {
  const PasswordForget({super.key});

  @override
  State<PasswordForget> createState() => _PasswordForgetState();
}

class _PasswordForgetState extends State<PasswordForget> {
  TextEditingController emailController = TextEditingController();
  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            dialogBox(context);
          },
          child: const Text(
            "Forgot Password?",
            style: TextStyle(
                fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void dialogBox(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(),
                      const Text(
                        "Forgot Password",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter your email",
                        hintText: "Eg: xploverse@example.com"),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        await auth
                            .sendPasswordResetEmail(email: emailController.text)
                            .then((value) {
                          // Show this msg if success
                          showSnackBar(context,
                              'We have sent a password reset link in your recovery email, Please check!');
                        }).onError((error, stackTrace) {
                          // Show this msg if err
                          showSnackBar(context, error.toString());
                        });
                        // Close the dialogbox after send
                        Navigator.pop(context);
                        // Clear the text field
                        emailController.clear();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text(
                        "Send",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black),
                      )),
                ],
              ),
            ),
          );
        });
  }
}
