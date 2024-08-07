import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_xploverse/providers/booked_provider.dart';
import 'package:flutter_xploverse/screens/auth/login.dart';
import 'package:flutter_xploverse/models/auth/authentication.dart';
import 'package:flutter_xploverse/screens/events/events_creation.dart';
import 'package:flutter_xploverse/screens/tickets/tickets_screen.dart';
import 'package:flutter_xploverse/screens/home/fade_page_route.dart';
import 'package:flutter_xploverse/screens/home/profile_screen.dart';
import 'package:flutter_xploverse/screens/map/map_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDarkMode = true; // Default to dark mode
  int _currentIndex = 0;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  final List<Widget> _children = [
    const MapPage(),
    const EventsCreation(),
    const TicketsScreen(),
    const ProfileScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final ThemeData theme = _isDarkMode ? ThemeData.dark() : ThemeData.light();

    final numberOfEventsInBooked = ref.watch(bookedNotifierProvider).length;

    return Theme(
      data: theme.copyWith(
        primaryColor: const Color.fromARGB(255, 10, 123, 158),
        appBarTheme: AppBarTheme(
          backgroundColor: _isDarkMode ? Colors.black54 : Colors.white54,
          foregroundColor: _isDarkMode ? Colors.white54 : Colors.black54,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        extendBody:
            true, // This allows the body to extend behind the bottom nav bar
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                "images/XploverseLogo.svg",
                height: 55.0,
              ),
              const SizedBox(
                  width: 5.0), // spacing between the logo and the title
              Text(_getAppBarTitle()),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _toggleTheme,
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
            const UserProfileDropdown(),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _children,
        ),
        bottomNavigationBar: LayoutBuilder(builder: (context, constraints) {
          // Calculate the available width
          double availableWidth = constraints.maxWidth;

          // Adjust the navigation bar height based on orientation
          double navBarHeight = availableWidth < 600 ? size.width * .155 : 60;

          // Calculate the icon size based on orientation
          double iconSize = availableWidth < 600 ? size.width * .076 : 30;

          return Container(
            margin: const EdgeInsets.all(20),
            height: navBarHeight,
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2), // Glass morphism background
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
                  itemCount: 4,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: size.width * .024),
                  itemBuilder: (context, index) => InkWell(
                    onTap: () => onTabTapped(index),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.fastLinearToSlowEaseIn,
                          margin: EdgeInsets.only(
                            bottom:
                                index == _currentIndex ? 0 : size.width * .029,
                            right: size.width * .0422,
                            left: size.width * .0422,
                          ),
                          width: size.width * .128,
                          height:
                              index == _currentIndex ? size.width * .014 : 0,
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
                              size: iconSize, // Use calculated icon size
                              color: index == _currentIndex
                                  ? (_isDarkMode ? Colors.white : Colors.black)
                                  : const Color.fromARGB(255, 10, 123, 158),
                            ),
                            if (index == 2 && numberOfEventsInBooked > 0)
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
        }),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'HOME';
      case 1:
        return 'EVENTS';
      case 2:
        return 'TICKETS';
      case 3:
        return 'PROFILE';
      default:
        return 'XPLOVERSE';
    }
  }

  List<IconData> listOfIcons = [
    Icons.map,
    Icons.event,
    Icons.bookmark,
    Icons.person_rounded,
  ];
}

// DropdownButton
class UserProfileDropdown extends StatelessWidget {
  const UserProfileDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 20,
        backgroundColor: const Color.fromARGB(255, 10, 123, 158),
        child: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              FirebaseAuth.instance.currentUser!.photoURL ?? '',
            )),
      ),
      onSelected: (String value) async {
        if (value == 'Logout') {
          await AuthServices().signOut();
          Navigator.of(context).pushReplacement(
            FadePageRoute(page: const LoginScreen()),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            value: 'Logout',
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ];
      },
    );
  }
}
