import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_xploverse/Authentication/LoginWithGoogle/google_auth.dart';
import 'package:flutter_xploverse/Authentication/PasswordForget/password_forget.dart';
import 'package:flutter_xploverse/Home/Screen/fade_page_route.dart';
import 'package:flutter_xploverse/Home/Screen/home_screen.dart';
import 'package:flutter_xploverse/Authentication/Screen/signup.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';
import 'package:flutter_xploverse/Authentication/Widgets/snackbar.dart';
import 'package:flutter_xploverse/Authentication/Widgets/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthServices().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      Navigator.of(context).pushReplacement(
        FadePageRoute(page: const HomeScreen()),
      );
    } else {
      showSnackBar(context, res);
    }
  }

  void _signInWithGoogle() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    String result = await _firebaseServices.signInWithGoogle("Explorer");

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (result == "success") {
      Navigator.pushReplacement(
        context,
        FadePageRoute(page: const HomeScreen()),
      );
    } else {
      showSnackBar(context, result);
    }
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
                height: height / 3.5,
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
                  onPressed: _signInWithGoogle,
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
                      Navigator.pushReplacement(
                        context,
                        FadePageRoute(page: const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      "Sign up here",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom)
            ],
          ),
        ),
      ),
    );
  }
}
