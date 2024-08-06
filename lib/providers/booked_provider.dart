import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/models/auth/event.dart';

class BookedNotifier extends Notifier<Set<Event>> {
  // Inintial Value
  @override
  Set<Event> build() {
    return {
      Event(
          id: '2',
          organizerId: 'of76dLxFp0T3FdDWdJOBNkRZdQo1',
          title: "Glastonbury Festival",
          description:
              "A legendary festival with a mix of music, arts, and performance, featuring iconic headliners.",
          address: "Pilton, UK",
          lat: 51.1819,
          lon: -2.6738,
          images: [
            "images/ev.jpg",
          ],
          startDate: DateTime(2024, 6, 26),
          endDate: DateTime(2024, 6, 30),
          maxParticipants: 200000,
          ticketsBooked: 100000,
          ticketPrice: 21.99),
      Event(
        id: '9',
        organizerId: 'YThTSRn5DQOFQLaTQ0KT8QUMSiu1',
        title: "CES",
        description:
            "The world's largest consumer electronics show, showcasing the latest technology and gadgets.",
        address: "Las Vegas, NV, USA",
        lat: 36.1699,
        lon: -115.1398,
        images: [
          "images/ev.jpg",
        ],
        startDate: DateTime(2024, 1, 7),
        endDate: DateTime(2024, 1, 10),
        maxParticipants: 170000,
        ticketsBooked: 100000,
        ticketPrice: 28.99,
      ),
    };
  }

  // Methods to Update the State
  // Add Event
  void addEvent(Event event) {
    // Check if an event with the same ID already exists
    if (!state.any((existingEvent) => existingEvent.id == event.id)) {
      state = {...state, event};
    }
  }

  // Remove Event
  void removeEvent(Event event) {
    state =
        state.where((existingEvent) => existingEvent.id != event.id).toSet();
  }
}

final bookedNotifierProvider = NotifierProvider<BookedNotifier, Set<Event>>(() {
  return BookedNotifier();
});
