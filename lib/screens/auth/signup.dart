import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_xploverse/screens/home/fade_page_route.dart';
import 'package:flutter_xploverse/screens/home/home_screen.dart';
import 'package:flutter_xploverse/screens/auth/login.dart';
import 'package:flutter_xploverse/models/auth/authentication.dart';
import 'package:flutter_xploverse/shared/button.dart';
import 'package:flutter_xploverse/shared/custom_dropdown.dart';
import 'package:flutter_xploverse/shared/snackbar.dart';
import 'package:flutter_xploverse/shared/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String selectedUserType = 'Explorer';
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    organizationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void signUpUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthServices().signUpUser(
      email: emailController.text,
      password: passwordController.text,
      username: usernameController.text,
      usertype: selectedUserType,
      organization:
          selectedUserType == 'Organizer' ? organizationController.text : null,
      phone: selectedUserType == 'Organizer' ? phoneController.text : null,
    );

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                height: MediaQuery.of(context).size.height / 3.5,
                child: SvgPicture.asset("images/XploverseLogo.svg"),
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
              TextFieldInput(
                textEditingController: usernameController,
                hintText: selectedUserType == 'Organizer'
                    ? "Enter organizer name"
                    : "Enter your username",
                icon: Icons.person,
              ),
              if (selectedUserType == 'Organizer') ...[
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
              const SizedBox(height: 20),
              MyButtons(
                onTap: signUpUser,
                text: 'Sign Up',
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        FadePageRoute(page: const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Login here",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
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
