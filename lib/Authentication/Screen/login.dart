import 'package:flutter/material.dart';
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
  // controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void despose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUser() async {
    String res = await AuthServices().loginUser(
        email: emailController.text, password: passwordController.text);

    // if login success, show user success msg and go to next page else show err msg
    if (res == "success") {
      setState(() {
        isLoading = true;
      });
      // navigate to next ui
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      setState(() {
        isLoading = false;
      });
      // show err msg
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SizedBox(
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
                  icon: Icons.email),
              TextFieldInput(
                  textEditingController: passwordController,
                  hintText: "Enter your password",
                  isPass: true,
                  icon: Icons.lock),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Forget Password?",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue),
                  ),
                ),
              ),
              MyButtons(
                onTap: loginUser,
                text: 'Login',
              ),
              SizedBox(height: height / 30),
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
                                builder: (context) => const SignUpScreen()));
                      },
                      child: const Text(
                        "Sign up here",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      )),
                ],
              )
            ],
          ),
        )));
  }
}
