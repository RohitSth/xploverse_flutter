import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrganizerSignupScreen extends StatefulWidget {
  const OrganizerSignupScreen({super.key});

  @override
  State<OrganizerSignupScreen> createState() => _OrganizerSignupScreenState();
}

class _OrganizerSignupScreenState extends State<OrganizerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();

  Future<void> _submitOrganizerDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Generate a unique organizer code
        String organizerCode = FirebaseFirestore.instance
            .collection('organizer_requests')
            .doc()
            .id
            .substring(0, 6)
            .toUpperCase();

        // Save organizer details to Firestore
        await FirebaseFirestore.instance.collection('organizer_requests').add({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'organization': _organizationController.text,
          'organizerCode': organizerCode,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Show success dialog with organizer code
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Organizer Request Submitted'),
              content: Text(
                  'Your organizer code is: $organizerCode\n\nPlease keep this code safe. You will need it to login as an organizer once your request is approved.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Return to previous screen
                  },
                ),
              ],
            );
          },
        );
      } catch (e) {
        print(e.toString());
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('An error occurred. Please try again.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Organizer Signup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _organizationController,
              decoration: InputDecoration(labelText: 'Organization Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your organization name';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Submit'),
              onPressed: _submitOrganizerDetails,
            ),
          ],
        ),
      ),
    );
  }
}
