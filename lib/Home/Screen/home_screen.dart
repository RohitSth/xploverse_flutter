import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/Screen/login.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Map/Screen/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDarkMode = true; // Default to dark mode

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            // MapPage taking the full screen
            const MapPage(),

            // AppBar and User Profile dropdown
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: const Text(
                  "XPLOVERSE",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    onPressed: _toggleTheme,
                    icon: Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const UserProfileDropdown(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileDropdown extends StatelessWidget {
  const UserProfileDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundImage: NetworkImage(
          FirebaseAuth.instance.currentUser!.photoURL ?? '',
        ),
      ),
      onSelected: (String value) async {
        if (value == 'Logout') {
          await AuthServices().signOut();
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        } else if (value == 'Profile') {
          // Navigate to the profile page (assuming you have one)
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()));
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            value: 'Profile',
            child: Text('View Profile'),
          ),
          const PopupMenuItem<String>(
            value: 'Logout',
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ];
      },
    );
  }
}

// Dummy ProfileScreen for navigation
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(FirebaseAuth.instance.currentUser!.photoURL ?? ''),
            Text(FirebaseAuth.instance.currentUser!.email ?? ''),
            Text(FirebaseAuth.instance.currentUser!.displayName ?? ''),
          ],
        ),
      ),
    );
  }
}
