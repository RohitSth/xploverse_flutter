import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_xploverse/Authentication/Screen/login.dart';
import 'package:flutter_xploverse/Authentication/Services/authentication.dart';
import 'package:flutter_xploverse/Events/Screen/events_screen.dart';
import 'package:flutter_xploverse/Events/Screen/tickets_screen.dart';
import 'package:flutter_xploverse/Home/Screen/fade_page_route.dart';
import 'package:flutter_xploverse/Home/Screen/profile_screen.dart';
import 'package:flutter_xploverse/Map/Screen/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDarkMode = true; // Default to dark mode
  int _currentIndex = 0;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  final List<Widget> _children = [
    const MapPage(),
    const EventsScreen(),
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

    return Theme(
      data: theme.copyWith(
        primaryColor: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          foregroundColor: _isDarkMode ? Colors.white : Colors.black,
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
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(20),
          height: size.width * .155,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.black54 : Colors.white54,
            border: Border.all(
              color: const Color.fromARGB(255, 79, 155, 218),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            borderRadius: BorderRadius.circular(50),
          ),
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
                      bottom: index == _currentIndex ? 0 : size.width * .029,
                      right: size.width * .0422,
                      left: size.width * .0422,
                    ),
                    width: size.width * .128,
                    height: index == _currentIndex ? size.width * .014 : 0,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 79, 155, 218),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                  ),
                  Icon(
                    listOfIcons[index],
                    size: size.width * .076,
                    color: index == _currentIndex
                        ? (_isDarkMode ? Colors.white : Colors.black)
                        : const Color.fromARGB(255, 79, 155, 218),
                  ),
                  SizedBox(height: size.width * .03),
                ],
              ),
            ),
          ),
        ),
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
        backgroundImage: NetworkImage(
          FirebaseAuth.instance.currentUser!.photoURL ?? '',
        ),
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
