import 'package:flutter/material.dart';

class EventsCreation extends StatefulWidget {
  const EventsCreation({super.key});

  @override
  State<EventsCreation> createState() => _EventsCreationState();
}

class _EventsCreationState extends State<EventsCreation> {
  // Controller
  final TextEditingController titleController = TextEditingController();

  // open a dialog box to add an event
  void openEventBox() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: titleController,
              ),
              actions: [
                // Button to save
                ElevatedButton(onPressed: () {}, child: Text("Add"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85.0),
        child: FloatingActionButton(
          onPressed: openEventBox,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
