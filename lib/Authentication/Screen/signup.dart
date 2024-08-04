import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/Screen/home_screen.dart';
import 'package:flutter_xploverse/Authentication/Screen/login.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';
import 'package:flutter_xploverse/Authentication/Widgets/custom_dropdown.dart';
import 'package:flutter_xploverse/Authentication/Widgets/snackbar.dart';
import 'package:flutter_xploverse/Authentication/Widgets/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  String selectedUserType = 'Explorer';
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
  }

  void signUpUser() async {
    String res = await AuthServices().signUpUser(
      username: usernameController.text,
      email: emailController.text,
      password: passwordController.text,
      usertype: selectedUserType,
    );

    if (res == "success") {
      setState(() {
        isLoading = true;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
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
                height: height / 3.5,
                child: Image.asset("images/LogoXp.jpg"),
              ),
              CustomDropdown(
                initialValue: selectedUserType,
                items: const [
                  DropdownMenuItem(value: 'Explorer', child: Text('Explorer')),
                  DropdownMenuItem(
                      value: 'Organizer', child: Text('Organizer')),
                ],
                onChanged: (newValue) {
                  setState(() {
                    selectedUserType = newValue!;
                  });
                },
              ),
              TextFieldInput(
                textEditingController: usernameController,
                hintText: "Enter your username",
                icon: Icons.person,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Forget Password?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              MyButtons(
                onTap: signUpUser,
                text: 'Sign Up',
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
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Login here",
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
