import 'package:flutter/material.dart';
import 'package:flutter_xploverse/Authentication/Widgets/button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("HomePage"),
        ),
        body: Center(
            child: Column(
          children: [
            Text("HomePage Welcome"),
            MyButtons(
              onTap: () {},
              text: 'Logout',
            )
          ],
        )));
  }
}
