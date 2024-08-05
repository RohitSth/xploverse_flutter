import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_xploverse/Authentication/LoginWithGoogle/google_auth.dart';
import 'package:flutter_xploverse/Authentication/PasswordForget/password_forget.dart';
import 'package:flutter_xploverse/Home/Screen/home_screen.dart';
import 'package:flutter_xploverse/Authentication/Screen/signup.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';
import 'package:flutter_xploverse/Authentication/Widgets/snackbar.dart';
import 'package:flutter_xploverse/Authentication/Widgets/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController organizerCodeController = TextEditingController();
  bool isLoading = false;

  final FirebaseServices _firebaseServices = FirebaseServices();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUser() async {
    String res = await AuthServices().loginUser(
        email: emailController.text, password: passwordController.text);

    if (res == "success") {
      setState(() {
        isLoading = true;
      });
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
    }
  }

  void _signInWithGoogle(String userType) async {
    setState(() {
      isLoading = true;
    });

    String result = await FirebaseServices().signInWithGoogle(userType);

    setState(() {
      isLoading = false;
    });

    if (result == "success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else if (result == "additional_info_needed") {
      // Show a dialog or navigate to a new screen to collect additional organizer information
      _showOrganizerInfoDialog();
    } else {
      showSnackBar(context, result);
    }
  }

  void _showOrganizerInfoDialog() {
    TextEditingController organizationController = TextEditingController();
    TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Additional Information Needed"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFieldInput(
                textEditingController: organizationController,
                hintText: "Enter organization name",
                icon: Icons.business,
              ),
              TextFieldInput(
                textEditingController: phoneController,
                hintText: "Enter phone number",
                icon: Icons.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Submit"),
              onPressed: () async {
                String result =
                    await FirebaseServices().completeOrganizerSignup(
                  FirebaseAuth.instance.currentUser!.uid,
                  organizationController.text,
                  phoneController.text,
                );
                Navigator.of(context).pop();
                if (result == "success") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                } else {
                  showSnackBar(context, result);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: height / 2.7,
                child: SvgPicture.asset("images/XploverseLogo.svg"),
              ),
              TextFieldInput(
                textEditingController: emailController,
                hintText: "Enter your email",
                icon: Icons.email,
              ),
              TextFieldInput(
                textEditingController: passwordController,
                hintText: "Enter your password",
                isPass: true,
                icon: Icons.lock,
              ),
              const PasswordForget(),
              MyButtons(
                onTap: loginUser,
                text: 'Login',
              ),
              const Center(
                child: Text(
                  " OR ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => _signInWithGoogle("Explorer"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Image.network(
                          "https://cdn4.iconfinder.com/data/icons/logos-brands-7/512/google_logo-google_icongoogle-512.png",
                          height: 30,
                        ),
                      ),
                      const Text(
                        "Login with Google",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color.fromARGB(255, 50, 139, 255),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height / 90),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      "Sign up here",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height: MediaQuery.of(context)
                      .viewInsets
                      .bottom) // Extra padding to ensure the content is visible when the keyboard is shown
            ],
          ),
        ),
      ),
    );
  }
}
