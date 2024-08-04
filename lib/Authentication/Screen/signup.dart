import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/Screen/home_screen.dart';
import 'package:flutter_xploverse/Authentication/Screen/login.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';
import 'package:flutter_xploverse/Authentication/Widgets/custom_dropdown.dart';
import 'package:flutter_xploverse/Authentication/Widgets/snackbar.dart';
import 'package:flutter_xploverse/Authentication/Widgets/text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height / 3.5,
                  child: Image.asset("images/LogoXp.jpg"),
                ),
                CustomDropdown(
                  initialValue: selectedUserType,
                  items: const [
                    DropdownMenuItem(
                        value: 'Explorer', child: Text('Explorer')),
                    DropdownMenuItem(
                        value: 'Organizer', child: Text('Organizer')),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      selectedUserType = newValue!;
                    });
                  },
                ),
                SizedBox(height: 20),
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
                SizedBox(height: 20),
                MyButtons(
                  onTap: signUpUser,
                  text: 'Sign Up',
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?"),
                    SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text(
                        "Login here",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
