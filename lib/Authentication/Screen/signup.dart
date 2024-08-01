import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/Screen/login.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';
import 'package:flutter_xploverse/Authentication/Widgets/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
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
                  textEditingController: usernameController,
                  hintText: "Enter your username",
                  icon: Icons.person),
              TextFieldInput(
                  textEditingController: emailController,
                  hintText: "Enter your email",
                  icon: Icons.email),
              TextFieldInput(
                  textEditingController: passwordController,
                  hintText: "Enter your password",
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
                onTap: () {},
                text: 'Login',
              ),
              SizedBox(height: height / 30),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(fontSize: 14),
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()));
                      },
                      child: const Text(
                        "Login here",
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
