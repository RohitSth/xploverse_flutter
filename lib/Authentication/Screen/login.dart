import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/LoginWithGoogle/google_auth.dart';
import 'package:flutter_xploverse/Authentication/PasswordForget/password_forget.dart';
import 'package:flutter_xploverse/Authentication/Screen/home_screen.dart';
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

  void _showGoogleSignInDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Choose your role"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _signInWithGoogle("Explorer"),
                child: Text("Sign in as Explorer"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _signInWithGoogle("Organizer"),
                child: Text("Sign in as Organizer"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _signInWithGoogle(String userType) async {
    Navigator.of(context).pop(); // Close the dialog
    setState(() {
      isLoading = true;
    });

    String result = await _firebaseServices.signInWithGoogle(userType);

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
    } else {
      showSnackBar(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: height / 2.7,
                child: Image.asset("images/LogoXp.jpg"),
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
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.black26)),
                  const Text(" or "),
                  Expanded(child: Container(height: 1, color: Colors.black26)),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 159, 184, 196),
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _showGoogleSignInDialog,
                  child: Row(
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
                          color: Colors.white,
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
                    style: TextStyle(fontSize: 14),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
