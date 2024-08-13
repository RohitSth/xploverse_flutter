import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/firebase_options.dart';
import 'package:flutter_xploverse/features/splash/presentation/view/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
  } catch (e) {
    print("Failed to load environment variables: $e");
  }

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  // Request permissions
  await requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.locationAlways,
    Permission.locationWhenInUse,
    Permission.camera,
    Permission.storage,
  ].request();

  statuses.forEach((permission, status) {
    if (!status.isGranted) {
      print('${permission.toString()} permission is not granted');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
