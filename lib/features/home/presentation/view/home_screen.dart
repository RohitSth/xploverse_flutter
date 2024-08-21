import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_xploverse/features/event/presentation/view/tickets_view/events_dashboard.dart';
import 'package:flutter_xploverse/features/event/presentation/navigator/booked_provider.dart';
import 'package:flutter_xploverse/features/auth/presentation/view/login.dart';
import 'package:flutter_xploverse/features/auth/presentation/viewmodel/authentication.dart';
import 'package:flutter_xploverse/features/event/presentation/view/events_management.dart';
import 'package:flutter_xploverse/features/event/presentation/view/event_screen.dart';
import 'package:flutter_xploverse/features/home/presentation/view/bottom_view/fade_page_route.dart';
import 'package:flutter_xploverse/features/home/presentation/view/bottom_view/profile_screen.dart';
import 'package:flutter_xploverse/features/map/presentation/view/map_screen.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userTypeProvider = FutureProvider<String>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authState.uid)
        .get();
    return userDoc.data()?['usertype'] ?? 'Explorer';
  }
  return 'Explorer';
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDarkMode = true;
  int _currentIndex = 0;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _updateStatusBarColor();
    });
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _updateStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateStatusBarColor();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userType = ref.watch(userTypeProvider);

    return authState.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              FadePageRoute(page: const LoginScreen()),
            );
          });
          return Container();
        }

        return userType.when(
          loading: () => const Text(""),
          error: (err, stack) => Text('Error: $err'),
          data: (userType) {
            final Size size = MediaQuery.of(context).size;
            final ThemeData theme =
                _isDarkMode ? ThemeData.dark() : ThemeData.light();
            final numberOfEventsInBooked =
                ref.watch(bookedNotifierProvider).length;

            final List<Widget> _children = [
              const MapPage(),
              const EventsScreen(),
              if (userType != 'Organizer') const ProfileDashboard(),
              if (userType == 'Organizer') const EventsManagement(),
              const ProfileScreen(),
            ];

            final List<IconData> listOfIcons = [
              Icons.map,
              Icons.event,
              if (userType != 'Organizer') Icons.bookmark,
              if (userType == 'Organizer') Icons.energy_savings_leaf_outlined,
              Icons.person_rounded,
            ];

            return Theme(
              data: theme.copyWith(
                primaryColor: const Color.fromARGB(255, 10, 123, 158),
              ),
              child: Scaffold(
                extendBody: true,
                body: Stack(
                  children: [
                    IndexedStack(
                      index: _currentIndex,
                      children: _children,
                    ),
                    Positioned(
                      top: 30,
                      right: 10,
                      child: UserProfileDropdown(
                        toggleTheme: _toggleTheme,
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: LayoutBuilder(
                  builder: (context, constraints) {
                    double availableWidth = constraints.maxWidth;
                    double navBarHeight =
                        availableWidth < 600 ? size.width * .155 : 60;
                    double iconSize =
                        availableWidth < 600 ? size.width * .076 : 30;

                    return Container(
                      margin: const EdgeInsets.all(20),
                      height: navBarHeight,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(255, 10, 123, 158),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: ListView.builder(
                            itemCount: listOfIcons.length,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                                horizontal: size.width * .024),
                            itemBuilder: (context, index) => InkWell(
                              onTap: () => onTabTapped(index),
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 1500),
                                    curve: Curves.fastLinearToSlowEaseIn,
                                    margin: EdgeInsets.only(
                                      bottom: index == _currentIndex
                                          ? 0
                                          : size.width * .029,
                                      right: size.width * .0422,
                                      left: size.width * .0422,
                                    ),
                                    width: size.width * .128,
                                    height: index == _currentIndex
                                        ? size.width * .014
                                        : 0,
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 79, 155, 218),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        listOfIcons[index],
                                        size: iconSize,
                                        color: index == _currentIndex
                                            ? Colors.white
                                            : const Color.fromARGB(
                                                255, 10, 123, 158),
                                      ),
                                      if (index == 2 &&
                                          numberOfEventsInBooked > 0)
                                        Positioned(
                                          top: 3,
                                          left: 5,
                                          child: Container(
                                            height: 19,
                                            width: 19,
                                            alignment: Alignment.center,
                                            child: Text(
                                              numberOfEventsInBooked.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: size.width * .03),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserProfileDropdown extends ConsumerWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const UserProfileDropdown({
    required this.toggleTheme,
    required this.isDarkMode,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Icon(Icons.error),
      data: (user) {
        if (user == null) return Container();
        return FutureBuilder<String?>(
          future: _getProfilePicture(user),
          builder: (context, snapshot) {
            final profilePicUrl = snapshot.data;
            return PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: const Color.fromARGB(255, 10, 123, 158),
                child: profilePicUrl != null
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(profilePicUrl),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
              onSelected: (String value) async {
                if (value == 'Logout') {
                  await AuthServices().signOut();
                } else if (value == 'Toggle Theme') {
                  toggleTheme();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Toggle Theme',
                    child: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Logout',
                    child: Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ];
              },
            );
          },
        );
      },
    );
  }

  Future<String?> _getProfilePicture(User user) async {
    // Check if user is signed in with Google
    final isGoogleSignIn = user.providerData
        .any((userInfo) => userInfo.providerId == 'google.com');

    if (isGoogleSignIn && user.photoURL != null) {
      return user.photoURL;
    }

    // If not Google sign-in, fetch from Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc.data()?['profilePictureUrl'] as String?;
    } catch (e) {
      print('Error fetching profile picture: $e');
      return null;
    }
  }
}
